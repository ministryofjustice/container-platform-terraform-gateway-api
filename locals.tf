locals {
  cluster_base_domain = var.cluster_base_domain
  gateway_namespace   = var.gateway_namespace

  coraza_cp_config = yamldecode(templatefile("${path.module}/templates/coraza-cp-conf.yaml.tpl", {
    gateway_namespace = var.gateway_namespace
  }))
}
