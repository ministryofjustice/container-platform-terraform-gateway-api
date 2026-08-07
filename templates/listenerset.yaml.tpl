apiVersion: gateway.networking.k8s.io/v1
kind: ListenerSet
metadata:
  name: ${gateway_name}-listenerset
  namespace: ${gateway_namespace}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  parentRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: ${gateway_name}
    namespace: ${gateway_namespace}
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.${cluster_base_domain}"
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: default-certificate
      allowedRoutes:
        namespaces:
          from: All
        kinds:
          - group: gateway.networking.k8s.io
            kind: HTTPRoute
%{ for listener in custom_listeners ~}
    - name: ${listener.name}
      protocol: HTTPS
      port: 443
      hostname: "${listener.hostname}"
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: ${listener.secret_name}
      allowedRoutes:
        namespaces:
          from: All
        kinds:
          - group: gateway.networking.k8s.io
            kind: HTTPRoute
%{ endfor ~}
