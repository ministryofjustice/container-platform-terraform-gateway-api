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
          - SecRule REQUEST_URI "@streq /__cp_waf_test__" "id:900002,phase:1,deny,status:403,log,msg:'cp config test rule fired'"
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
          - Include /etc/coraza/cp/coraza-cp.conf
