variable "lb_name_prefix" {
  description = "Prefix used when constructing the AWS NLB name"
  type        = string
}

variable "envoy_proxy_replicas" {
  description = "Number of replicas for the EnvoyProxy deployment"
  type        = number
  default     = 2
}

variable "cluster_base_domain" {
  description = "Base domain for the cluster"
  type        = string
}

variable "gateway_namespace" {
  description = "Kubernetes namespace for Gateway resources"
  type        = string
  default     = "envoy-gateway-system"
}

variable "gateway_name" {
  description = "Name of the Gateway to create. Use 'default' for the first (shared-infra) call; use a unique name for additional gateways."
  type        = string
  default     = "default"
}
