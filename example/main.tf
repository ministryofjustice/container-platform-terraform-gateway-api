# Example: single gateway (default usage)
# Terraform workspace = cluster name (e.g. cp-1106-1413)

locals {
  cluster_name        = terraform.workspace
  cluster_base_domain = "development.container-platform.service.justice.gov.uk"
}

# -----------------------------------------------------------------------
# Single gateway — minimum required inputs
# -----------------------------------------------------------------------
module "gateway_api" {
  source = "../"

  lb_name_prefix      = local.cluster_name
  cluster_base_domain = local.cluster_base_domain

  # Optional — tune replicas
  # envoy_proxy_replicas = 3

  # Optional — customize gateway namespace
  # gateway_namespace = "envoy-gateway-system"

  # Optional — use a non-default gateway name
  # gateway_name = "default"
}

# -----------------------------------------------------------------------
# Multiple gateways — optional
# -----------------------------------------------------------------------
# module "gateway_api_2" {
#   source = "../"
#
#   lb_name_prefix      = local.cluster_name
#   cluster_base_domain = local.cluster_base_domain
#   gateway_name        = "new-waf"
# }
