resource "kubernetes_namespace_v1" "gateway_api_controller" {
  count = var.gateway_name == "default" ? 1 : 0

  metadata {
    name = "gateway-api-controller"

    labels = {
      "name"                                            = "gateway-api-controller"
      "container-platform.justice.gov.uk/is-production" = "true"
      "pod-security.kubernetes.io/enforce"              = "restricted"
    }

    annotations = {
      "container-platform.justice.gov.uk/application"           = "AWS Load Balancer Controller"
      "container-platform.justice.gov.uk/business-unit"         = "OCTO"
      "container-platform.justice.gov.uk/owner"                 = "Container Platform: platforms@digital.justice.gov.uk"
      "container-platform.service.justice.gov.uk/service-area"  = "Hosting"
      "container-platform.justice.gov.uk/source-code"           = "https://github.com/ministryofjustice/container-platform-terraform-gateway-api"
      "container-platform.justice.gov.uk/slack-channel"         = "cloud-platform"
      "container-platform.service.justice.gov.uk/is-production" = "true"
    }
  }
}

module "aws_lbc_pod_identity" {
  count   = var.gateway_name == "default" ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"

  name = "aws-load-balancer-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = "gateway-api-controller"
      service_account = "aws-load-balancer-controller"
    }
  }
}

resource "time_sleep" "wait_for_pod_identity_association" {
  count      = var.gateway_name == "default" ? 1 : 0
  depends_on = [module.aws_lbc_pod_identity]

  # EKS Pod Identity association can take a short time to propagate
  create_duration = "30s"
}

resource "helm_release" "aws_load_balancer_controller" {
  count      = var.gateway_name == "default" ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.4.0"
  namespace  = "gateway-api-controller"
  timeout    = 600

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "securityContext.capabilities.drop[0]"
      value = "ALL"
    },
    {
      name  = "securityContext.seccompProfile.type"
      value = "RuntimeDefault"
    }
  ]

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_namespace_v1.gateway_api_controller,
    time_sleep.wait_for_pod_identity_association,
  ]
}

