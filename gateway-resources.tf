# LoadBalancerConfiguration and GatewayClass are shared cluster-wide infra.
# Only created by the "default" module call — additional gateways reuse them.

resource "kubectl_manifest" "targetgroupconfiguration" {
  count = var.gateway_name == "default" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: gateway.k8s.aws/v1beta1
    kind: TargetGroupConfiguration
    metadata:
      name: internet-facing-tgc
      namespace: gateway-api-controller
    spec:
      defaultConfiguration:
        targetType: ip
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "kubectl_manifest" "loadbalancerconfiguration" {
  count = var.gateway_name == "default" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: gateway.k8s.aws/v1beta1
    kind: LoadBalancerConfiguration
    metadata:
      name: internet-facing
      namespace: gateway-api-controller
    spec:
      scheme: internet-facing
      ipAddressType: ipv4
      defaultTargetGroupConfiguration:
        name: internet-facing-tgc
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.targetgroupconfiguration]
}

resource "kubectl_manifest" "gatewayclass" {
  count = var.gateway_name == "default" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: amazon-alb
    spec:
      controllerName: gateway.k8s.aws/alb
      parametersRef:
        group: gateway.k8s.aws
        kind: LoadBalancerConfiguration
        name: internet-facing
        namespace: gateway-api-controller
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.loadbalancerconfiguration]
}

# One Gateway per call — name driven by var.gateway_name.
# Multiple gateways can exist under the same GatewayClass (amazon-alb).

resource "kubectl_manifest" "gateway" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: ${var.gateway_name}
      namespace: gateway-api-controller
      annotations:
        alb.ingress.kubernetes.io/certificate-arn: ${local.certificate_arn}
    spec:
      gatewayClassName: amazon-alb
      listeners:
        - name: http
          protocol: HTTP
          port: 80
          allowedRoutes:
            namespaces:
              from: All
        - name: https
          protocol: HTTPS
          port: 443
          allowedRoutes:
            namespaces:
              from: All
          tls:
            mode: Terminate
            options:
              alb.ingress.kubernetes.io/certificate-arn: ${local.certificate_arn}
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.gatewayclass,
    aws_acm_certificate_validation.cluster_wildcard,
  ]
}

resource "kubectl_manifest" "http_redirect" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: ${var.gateway_name}-http-to-https
      namespace: gateway-api-controller
    spec:
      parentRefs:
        - name: ${var.gateway_name}
          namespace: gateway-api-controller
          sectionName: http
      rules:
        - filters:
            - type: RequestRedirect
              requestRedirect:
                scheme: https
                statusCode: 301
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [kubectl_manifest.gateway]
}
