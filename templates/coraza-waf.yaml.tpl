apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: default-coraza-waf
  namespace: ${gateway_namespace}
  annotations:
    container-platform.service.justice.gov.uk/coraza-cp-config-hash: "${coraza_cp_config_hash}"
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
          # - SecAction "id:900001,phase:1,deny,status:403,log,msg:'inline waf test action fired'"
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
          - Include /etc/coraza/cp/coraza-cp.conf
