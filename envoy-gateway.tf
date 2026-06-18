# Envoy Gateway — installed only once (on the "default" gateway module call).
# Provides a second GatewayClass (gateway.envoyproxy.io) that users reference
# in their HTTPRoutes. Envoy does all L7 routing internally, so the ALB only
# needs a single target group pointing at the Envoy pods — bypassing the
# 100 listener-rule/TG limit on the ALB.
#
# Traffic flow:
#   Internet → ALB (WAF, 1 TG = envoy-gateway pods)
#                ↓  (catch-all HTTPRoute on the amazon-alb GatewayClass)
#          Envoy Gateway pods
#                ↓  (user HTTPRoutes on the gateway.envoyproxy.io GatewayClass)
#          Service A / B / C … (unlimited)

# ── Helm install ────────────────────────────────────────────────────────────

resource "helm_release" "envoy_gateway" {
  count = var.gateway_name == "default" ? 1 : 0

  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  namespace        = "envoy-gateway-system"
  create_namespace = true
  version          = "v1.4.1"

  set {
    name  = "deployment.replicas"
    value = "2"
  }

  # Expose Envoy Gateway pods via a NodePort service so the ALB (instance mode)
  # can reach them. Port 80 → container 8080, port 443 → container 8443.
  set {
    name  = "config.envoyGateway.gateway.controllerName"
    value = "gateway.envoyproxy.io/gatewayclass-controller"
  }
}

# ── GatewayClass for Envoy ───────────────────────────────────────────────────

resource "kubectl_manifest" "envoy_gatewayclass" {
  count = var.gateway_name == "default" ? 1 : 0

  depends_on = [helm_release.envoy_gateway]

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: envoy
    spec:
      controllerName: gateway.envoyproxy.io/gatewayclass-controller
  YAML
}

# ── Envoy Gateway instance (the Gateway users reference) ────────────────────

resource "kubectl_manifest" "envoy_gateway_instance" {
  count = var.gateway_name == "default" ? 1 : 0

  depends_on = [kubectl_manifest.envoy_gatewayclass]

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: envoy
      namespace: envoy-gateway-system
    spec:
      gatewayClassName: envoy
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
          tls:
            mode: Passthrough
          allowedRoutes:
            namespaces:
              from: All
  YAML
}

# ── Catch-all HTTPRoute: ALB → Envoy Gateway service ────────────────────────
# This single HTTPRoute wires the ALB (amazon-alb GatewayClass) to the
# Envoy Gateway service. All user traffic enters through here, then Envoy
# routes internally via user-defined HTTPRoutes on the "envoy" GatewayClass.

resource "kubectl_manifest" "alb_to_envoy_httproute" {
  count = var.gateway_name == "default" ? 1 : 0

  depends_on = [
    kubectl_manifest.gateway,
    kubectl_manifest.envoy_gateway_instance,
  ]

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: alb-to-envoy
      namespace: gateway-api-controller
    spec:
      parentRefs:
        - name: ${var.gateway_name}
          namespace: gateway-api-controller
      hostnames:
        - "*.${local.cluster_base_domain}"
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: envoy-gateway
              namespace: envoy-gateway-system
              port: 80
  YAML
}

# ── ReferenceGrant: allow gateway-api-controller ns to reach envoy-gateway-system ──

resource "kubectl_manifest" "envoy_reference_grant" {
  count = var.gateway_name == "default" ? 1 : 0

  depends_on = [helm_release.envoy_gateway]

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: ReferenceGrant
    metadata:
      name: allow-alb-to-envoy
      namespace: envoy-gateway-system
    spec:
      from:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          namespace: gateway-api-controller
      to:
        - group: ""
          kind: Service
  YAML
}
