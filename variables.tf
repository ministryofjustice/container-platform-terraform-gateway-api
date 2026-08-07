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

variable "custom_listeners" {
  description = <<-EOT
    Additional HTTPS listeners for custom domains that fall outside the cluster
    wildcard (*.cluster_base_domain). Each entry adds a listener to the shared
    ListenerSet, the cert-manager gateway-shim then issues a Certificate for the
    listener's hostname into the Secret named here, using the cluster-issuer
    annotation on the ListenerSet. Leave empty (the default) to preserve the
    original single-wildcard-listener behaviour exactly.
  EOT
  type = list(object({
    name        = string
    hostname    = string
    secret_name = string
  }))
  default = []

  validation {
    condition     = alltrue([for l in var.custom_listeners : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", l.name))])
    error_message = "Each custom_listeners[].name must be a valid lowercase DNS label (alphanumeric and hyphens, not starting or ending with a hyphen)."
  }

  validation {
    condition     = length(var.custom_listeners) == length(distinct([for l in var.custom_listeners : l.name]))
    error_message = "Each custom_listeners[].name must be unique within the ListenerSet."
  }
}
