apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: "${gateway_name}-envoy-proxy"
  namespace: ${gateway_namespace}
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyDeployment:
        name: "${gateway_name}-envoy-proxy"
        replicas: ${envoy_proxy_replicas}
        pod:
          volumes:
            - name: dynamic-modules
              image:
                reference: ghcr.io/tetratelabs/built-on-envoy/composer:0.6.0
                pullPolicy: IfNotPresent
        container:
          env:
            - name: GODEBUG
              value: "cgocheck=0"
          volumeMounts:
            - name: dynamic-modules
              mountPath: /etc/envoy/dynamic-modules
              readOnly: true
      envoyService:
        loadBalancerClass: eks.amazonaws.com/nlb
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-name                  : "${lb_name_prefix}-envoy-${gateway_name}"
          service.beta.kubernetes.io/aws-load-balancer-scheme                : "internet-facing"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type       : "ip"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol  : "TCP"
          service.beta.kubernetes.io/aws-load-balancer-healthcheck-port      : "traffic-port"
          service.beta.kubernetes.io/aws-load-balancer-attributes            : "load_balancing.cross_zone.enabled=true"
          service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=true
  dynamicModules:
    - name: composer
      source:
        type: Local
        local:
          path: /etc/envoy/dynamic-modules/libcomposer.so
      doNotClose: true
      loadGlobally: false
