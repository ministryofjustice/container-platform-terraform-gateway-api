apiVersion: v1
kind: ConfigMap
metadata:
  name: coraza-cp-config
  namespace: ${gateway_namespace}
data:
  coraza-cp.conf: |
    # Container Platform managed Coraza configuration.
    # This file may intentionally be empty.
    SecRuleUpdateTargetById 942290 "!REQUEST_COOKIES:/.*_posthog$/"
