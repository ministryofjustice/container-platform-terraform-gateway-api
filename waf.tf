# WAF WebACL — created once on the "default" gateway call.
# Additional gateways reuse it by passing var.waf_web_acl_arn.

resource "aws_wafv2_web_acl" "gateway" {
  count = var.gateway_name == "default" ? 1 : 0

  name        = "${var.cluster_name}-gateway"
  description = "WAF WebACL for Gateway API ALB on cluster ${var.cluster_name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS managed rule group — common threats (SQLi, XSS, known bad inputs)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.cluster_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule group — known bad inputs (Log4j, etc.)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.cluster_name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cluster_name}-gateway-waf"
    sampled_requests_enabled   = true
  }
}

locals {
  waf_web_acl_arn = var.waf_web_acl_arn != null ? var.waf_web_acl_arn : try(aws_wafv2_web_acl.gateway[0].arn, null)
}

# Poll until LBC has provisioned the ALB for this Gateway, then read it.
# The data source has depends_on pointing to this resource, which causes Terraform
# to defer the data source read to apply time (not plan time) on the first apply.
resource "terraform_data" "wait_for_alb" {
  triggers_replace = {
    cluster_name = var.cluster_name
    gateway_name = var.gateway_name
  }

  depends_on = [kubectl_manifest.gateway]

  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME = var.cluster_name
      GATEWAY_NAME = var.gateway_name
      AWS_REGION   = var.aws_region
    }

    command = <<-EOT
      echo "Waiting for LBC to provision ALB (cluster=$CLUSTER_NAME, gateway=$GATEWAY_NAME)..."
      MAX=80
      for i in $(seq 1 $MAX); do
        COUNT=$(aws resourcegroupstaggingapi get-resources \
          --region "$AWS_REGION" \
          --tag-filters \
            "Key=elbv2.k8s.aws/cluster,Values=$CLUSTER_NAME" \
            "Key=gateway.k8s.aws.alb/stack,Values=gateway-api-controller/$GATEWAY_NAME" \
          --resource-type-filters "elasticloadbalancing:loadbalancer" \
          --query "length(ResourceTagMappingList)" \
          --output text 2>/dev/null || echo 0)
        if [ "$COUNT" = "1" ]; then
          echo "ALB found after $i attempt(s)."
          exit 0
        fi
        echo "Attempt $i/$MAX: ALB not ready, retrying in 15s..."
        sleep 15
      done
      echo "ERROR: ALB did not appear after 20 minutes" >&2
      exit 1
    EOT
  }
}

# Look up the ALB that LBC provisioned for this Gateway.
# depends_on = [terraform_data.wait_for_alb] defers this read to apply time
# on the first apply, ensuring the ALB already exists when Terraform queries it.
data "aws_lb" "gateway" {
  tags = {
    "elbv2.k8s.aws/cluster"     = var.cluster_name
    "gateway.k8s.aws.alb/stack" = "gateway-api-controller/${var.gateway_name}"
  }

  depends_on = [terraform_data.wait_for_alb]
}

resource "aws_wafv2_web_acl_association" "gateway" {
  resource_arn = data.aws_lb.gateway.arn
  web_acl_arn  = local.waf_web_acl_arn
}
