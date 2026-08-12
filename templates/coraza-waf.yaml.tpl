apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: default-coraza-waf
  namespace: ${gateway_namespace}
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: ${gateway_name}
      namespace: ${gateway_namespace}
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine On
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
