# container-platform-terraform-gateway-api

[![Ministry of Justice Repository Compliance Badge](https://github-community.service.justice.gov.uk/repository-standards/api/container-platform-terraform-gateway-api/badge)](https://github-community.service.justice.gov.uk/repository-standards/container-platform-terraform-gateway-api)

Terraform module that installs and configures the full Gateway API stack on an EKS cluster, providing internet-facing HTTPS ingress via AWS Application Load Balancer.

## What this module does

### Shared infrastructure (`gateway_name = "default"` only)

The first module call creates all cluster-wide shared resources:

- **Gateway API CRDs** — installs the standard Kubernetes Gateway API CRDs (`GatewayClass`, `Gateway`, `HTTPRoute`, etc.) pinned to a tested version
- **AWS Load Balancer Controller** — deployed via Helm into the `gateway-api-controller` namespace with EKS Pod Identity (no static credentials)
- **ACM wildcard certificate** — `*.{cluster_name}.{cluster_base_domain}` with automatic Route53 DNS validation
- **WAFv2 WebACL** — AWS managed rule groups for common threats (SQLi, XSS) and known bad inputs (Log4j etc.), associated with the ALB
- **GatewayClass** (`amazon-alb`) — cluster-wide GatewayClass backed by the open-source LBC, not the EKS Auto Mode built-in controller
- **LoadBalancerConfiguration** and **TargetGroupConfiguration** — configure the ALB as internet-facing with IP target mode (requires VPC CNI)

> **IP target mode:** Pods are registered directly in ALB target groups by their VPC IP. This requires VPC CNI so pods have real VPC IPs. Traffic flows ALB → Pod directly, without kube-proxy. Tenant services can be `ClusterIP`.

### Per-gateway resources (every call)

Each module call (including `default`) creates:

- **Gateway** — an ALB per Gateway, with HTTP (port 80) and HTTPS (port 443) listeners. HTTP traffic is redirected to HTTPS via an HTTPRoute redirect rule
- **WAF association** — every ALB is associated with the shared WebACL

Tenants attach their `HTTPRoute` resources to a Gateway by name to expose their services via HTTPS.

### What this module does NOT do

- DNS records — managed by `external-dns` which watches `HTTPRoute` resources

## Usage

### Single gateway

```hcl
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=initial-gateway-api-with-aws-lbc"

  cluster_name        = local.cluster_name
  cluster_environment = local.cluster_environment
  vpc_id              = data.aws_vpc.selected.id
  # Optional — override if base domains change without updating the module
  # base_domain_map = {
  #   "development_cluster" = "development.container-platform.service.justice.gov.uk"
  #   "live"                = "live.container-platform.service.justice.gov.uk"
  # }

  # Optional — set when adding a second gateway to spread tenants across ALBs
  # gateway_name    = "default"
  # certificate_arn = null  # defaults to ACM cert created by this module
  # waf_web_acl_arn = null  # defaults to WAF WebACL created by this module}
```

## Requirements

The calling Terraform configuration must configure the following providers:

| Provider | Purpose |
|----------|---------|
| `aws` | IAM, ACM, Route53, WAF, ALB lookup |
| `helm` | Deploy AWS Load Balancer Controller |
| `kubectl` (`alekc/kubectl`) | Install Gateway API CRDs and k8s manifests |
| `kubernetes` | Create `gateway-api-controller` namespace |
| `time` | Wait for Pod Identity propagation |
| `http` | Fetch Gateway API CRD manifests from upstream |

> **Note on hardcoded versions:** The LBC Helm chart version (`3.4.0`) and Gateway API CRD version (`v1.5.1`) are intentionally hardcoded — they are a tested compatible pair. The pod identity module version is also hardcoded (`2.8.1`) due to a Terraform constraint: variables are not allowed in module `version` arguments. To upgrade, update all three together in a single commit.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `cluster_name` | EKS cluster name | yes | |
| `cluster_environment` | Environment key used to look up the base domain from `base_domain_map`. Ignored if `cluster_base_domain` is set directly | no | `null` |
| `base_domain_map` | Map of environment keys to base domains. The default map contains `development_cluster` and `live`. Add new environments here or pass an override at the call site — no module change needed | no | `{"development_cluster": "development.container-platform.service.justice.gov.uk", "live": "live.container-platform.service.justice.gov.uk"}` |
| `cluster_base_domain` | Exact base domain override. If set, `cluster_environment` and `base_domain_map` are ignored | no | `null` |
| `vpc_id` | VPC ID for the EKS cluster | yes | |
| `aws_region` | AWS region | no | `eu-west-2` |
| `gateway_name` | Name of the Gateway. Use `default` for the first call; unique name for additional gateways | no | `"default"` |
| `certificate_arn` | ACM certificate ARN. Defaults to the wildcard cert created by this module. Additional gateway calls must pass `module.<default>.certificate_arn` | no | `null` |
| `waf_web_acl_arn` | WAFv2 WebACL ARN. Defaults to the WebACL created by this module. Additional gateway calls must pass `module.<default>.waf_web_acl_arn` | no | `null` |

### Domain resolution order

The base domain is resolved in the following priority:

1. `cluster_base_domain` — exact value, highest priority
2. `base_domain_map[cluster_environment]` — looked up from the map
3. Error — if neither resolves (both null or key missing from map)

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | ARN of the ACM wildcard certificate. Pass to additional gateway calls |
| `waf_web_acl_arn` | ARN of the WAFv2 WebACL. Pass to additional gateway calls |
| `alb_arn` | ARN of the ALB provisioned for this Gateway |
| `lbc_role_arn` | ARN of the IAM role for AWS Load Balancer Controller (null for non-default gateways) |
| `gateway_name` | Name of the Gateway created by this module call |
| `gateway_namespace` | Namespace where the Gateway is deployed (`gateway-api-controller`) |
| `gateway_api_crd_ids` | Map of installed Gateway API CRD resource IDs |

## License

[MIT License](LICENSE)
