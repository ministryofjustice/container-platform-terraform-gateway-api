resource "kubectl_manifest" "envoy_gatewayclass" {
  yaml_body = templatefile("${path.module}/templates/gatewayclass.yaml.tpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = local.gateway_namespace
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "envoy_gateway_instance" {
  yaml_body = templatefile("${path.module}/templates/gateway.yaml.tpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = local.gateway_namespace
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "gateway_proxy" {
  yaml_body = templatefile("${path.module}/templates/envoyproxy.yaml.tpl", {
    lb_name_prefix       = var.lb_name_prefix
    envoy_proxy_replicas = var.envoy_proxy_replicas
    gateway_name         = var.gateway_name
    gateway_namespace    = local.gateway_namespace
  })

  server_side_apply = true
  wait              = true

  depends_on = [kubernetes_config_map_v1.coraza_cp_config]
}

resource "kubectl_manifest" "default_listenerset" {
  yaml_body = templatefile("${path.module}/templates/listenerset.yaml.tpl", {
    cluster_base_domain = local.cluster_base_domain
    gateway_name        = var.gateway_name
    gateway_namespace   = local.gateway_namespace
  })

  server_side_apply = true
  wait              = true
}

# Platform-managed Coraza configuration
# Allows the platform team to manage global WAF rule exclusions
resource "kubernetes_config_map_v1" "coraza_cp_config" {
  metadata {
    name      = local.coraza_cp_config.metadata.name
    namespace = local.coraza_cp_config.metadata.namespace
  }

  data = local.coraza_cp_config.data
}

# Gateway-level WAF policy with OWASP CRS
# This applies to ALL routes through the Gateway by default
# Teams can override this at the HTTPRoute level if needed
resource "kubernetes_manifest" "default_coraza_waf" {
  count = var.enable_owasp ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/templates/coraza-waf.yaml.tpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = local.gateway_namespace
  }))

  depends_on = [kubernetes_config_map_v1.coraza_cp_config]
}
