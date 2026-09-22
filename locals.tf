locals {
  cluster_base_domain = var.cluster_base_domain
  gateway_namespace   = var.gateway_namespace

  coraza_cp_config = yamldecode(templatefile("${path.module}/templates/coraza-cp-conf.yaml.tpl", {
    gateway_namespace = var.gateway_namespace
  }))

  coraza_cp_config_hash = sha256(jsonencode(local.coraza_cp_config.data))

  coraza_config_hash = sha256(join("", [
    local.coraza_cp_config_hash,
    filesha256("${path.module}/templates/coraza-waf.yaml.tpl"),
  ]))
}
