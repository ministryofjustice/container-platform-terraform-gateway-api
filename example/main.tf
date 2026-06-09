# Example: single gateway (default usage)
# Terraform workspace = cluster name (e.g. cp-1106-1413)

locals {
  cluster_name        = terraform.workspace
  cluster_environment = "development_cluster"
}

# -----------------------------------------------------------------------
# Single gateway — minimum required inputs
# -----------------------------------------------------------------------
module "gateway_api" {
  source = "../"

  cluster_name        = local.cluster_name
  cluster_environment = local.cluster_environment
  vpc_id              = data.aws_vpc.selected.id

  # Optional — override base domains without changing the module
  # base_domain_map = {
  #   "development_cluster" = "development.container-platform.service.justice.gov.uk"
  #   "live"                = "live.container-platform.service.justice.gov.uk"
  # }

  # Optional — uncomment when adding a second gateway (spread tenants across ALBs)
  # gateway_name    = "default"
  # certificate_arn = null  # pass module.gateway_api.certificate_arn on 2nd call
  # waf_web_acl_arn = null  # pass module.gateway_api.waf_web_acl_arn on 2nd call
}

# -----------------------------------------------------------------------
# Multiple gateways — uncomment when approaching the 100 target group
# or 100 listener rule ALB limit
# -----------------------------------------------------------------------
# module "gateway_api_2" {
#   source = "../"
#
#   cluster_name        = local.cluster_name
#   cluster_environment = local.cluster_environment
#   vpc_id              = data.aws_vpc.selected.id
#   gateway_name        = "default-2"
#   certificate_arn     = module.gateway_api.certificate_arn
#   waf_web_acl_arn     = module.gateway_api.waf_web_acl_arn
# }
