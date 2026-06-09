output "certificate_arn" {
  description = "ARN of the ACM certificate attached to this Gateway. Pass this to additional module calls via var.certificate_arn."
  value       = local.certificate_arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAFv2 WebACL attached to the Gateway ALB. Null when gateway_name != 'default'."
  value       = try(aws_wafv2_web_acl.gateway[0].arn, null)
}

output "alb_arn" {
  description = "ARN of the ALB provisioned for this Gateway."
  value       = data.aws_lb.gateway.arn
}

output "lbc_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller (Pod Identity). Null when gateway_name != 'default'."
  value       = try(module.aws_lbc_pod_identity[0].iam_role_arn, null)
}

output "gateway_name" {
  description = "Name of the Gateway created by this module call"
  value       = var.gateway_name
}

output "gateway_namespace" {
  description = "Namespace where the Gateway is deployed"
  value       = "gateway-api-controller"
}

output "gateway_api_crd_ids" {
  description = "Map of installed Gateway API CRD resource IDs"
  value       = { for k, v in kubectl_manifest.gateway_api_crds : k => v.uid }
}
