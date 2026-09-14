apiVersion: v1
kind: ConfigMap
metadata:
  name: coraza-cp-config
  namespace: ${gateway_namespace}
data:
  coraza-cp.conf: |
    # Container Platform managed Coraza configuration.
    # This file may intentionally be empty.
    # SecRule REQUEST_URI "@streq /__cp_waf_test__" "id:900002,phase:1,deny,status:403,log,msg:'cp config test rule fired'"
    # - SecAction "id:900001,phase:1,deny,status:403,log,msg:'inline waf test action fired'"

