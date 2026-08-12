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

resource "kubernetes_manifest" "default_coraza_waf" {
  count = var.enable_owasp ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/templates/coraza-waf.yaml.tpl", {
    gateway_name      = var.gateway_name
    gateway_namespace = local.gateway_namespace
  }))
}
