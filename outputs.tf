output "gateway_name" {
  description = "Name of the Gateway created by this module call"
  value       = var.gateway_name
}

output "gateway_namespace" {
  description = "Namespace where the Gateway is deployed"
  value       = local.gateway_namespace
}
