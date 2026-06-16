variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_environment" {
  description = "Cluster environment key used to look up the base domain from base_domain_map. Ignored if cluster_base_domain is set directly. Must be set if cluster_base_domain is null."
  type        = string
  default     = null
}

variable "base_domain_map" {
  description = "Map of cluster_environment keys to base domains. Override this when your platform uses non-standard domains."
  type        = map(string)
  default = {
    "development_cluster" = "development.container-platform.service.justice.gov.uk"
    "nonlive"             = "nonlive.container-platform.service.justice.gov.uk"
    "preproduction"       = "preproduction.container-platform.service.justice.gov.uk"
    "live"                = "live.container-platform.service.justice.gov.uk"
  }
}

variable "cluster_base_domain" {
  description = "Base domain for the cluster. If null, derived from cluster_environment using the standard Container Platform domain map."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "gateway_name" {
  description = "Name of the Gateway to create. Use 'default' for the first (shared-infra) call; use a unique name for additional gateways."
  type        = string
  default     = "default"
}

variable "waf_web_acl_arn" {
  description = "ARN of an existing WAFv2 WebACL to associate with this Gateway's ALB. Defaults to null — the 'default' gateway call creates its own WebACL. Additional gateway calls should pass module.<default>.waf_web_acl_arn."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN to attach to the Gateway HTTPS listener. Defaults to the wildcard cert created by this module (gateway_name = 'default'). Additional gateway calls must pass this explicitly from module.<default>.certificate_arn."
  type        = string
  default     = null
}
