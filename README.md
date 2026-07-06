# container-platform-terraform-gateway-api

[![Ministry of Justice Repository Compliance Badge](https://github-community.service.justice.gov.uk/repository-standards/api/container-platform-terraform-gateway-api/badge)](https://github-community.service.justice.gov.uk/repository-standards/container-platform-terraform-gateway-api)

Terraform module that creates Gateway API and EnvoyProxy resources on an EKS cluster for a named gateway entrypoint backed by an NLB service.

This module handles the **gateway resource layer only**. Install the Envoy Gateway controller and CRDs separately with [container-platform-terraform-envoy-gateway](https://github.com/ministryofjustice/container-platform-terraform-envoy-gateway).

## What this module creates

Each module call creates:

- A `GatewayClass` named `<gateway_name>-envoy`
- A `Gateway` named `<gateway_name>` with an HTTP listener on port 80
- An `EnvoyProxy` that configures the Envoy data plane as an internet-facing NLB with name `<lb_name_prefix>-envoy-<gateway_name>`
- A `ListenerSet` named `<gateway_name>-listenerset` with HTTPS on 443 and TLS secret reference `default-certificate`, with hostname `*.${cluster_base_domain}`

All resources are created in the namespace specified by `gateway_namespace` (defaults to `envoy-gateway-system`).

## Usage

Single gateway:

```hcl
module "gateway_api" {
  source = "github.com/ministryofjustice/container-platform-terraform-gateway-api?ref=<tag-or-sha>"

  lb_name_prefix      = local.cluster_name
  cluster_base_domain = "development.container-platform.service.justice.gov.uk"

  # Optional
  # gateway_name         = "default"
  # gateway_namespace    = "envoy-gateway-system"
  # envoy_proxy_replicas = 3
}
```

See the runnable example in `example/main.tf`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `lb_name_prefix` | Prefix used in NLB naming | `string` | n/a | Yes |
| `cluster_base_domain` | Base domain for the cluster | `string` | n/a | Yes |
| `gateway_name` | Name prefix for Gateway, GatewayClass, EnvoyProxy, and ListenerSet resources | `string` | `"default"` | No |
| `gateway_namespace` | Kubernetes namespace for Gateway resources | `string` | `"envoy-gateway-system"` | No |
| `envoy_proxy_replicas` | Envoy data plane replica count | `number` | `2` | No |

## Outputs

| Name | Description |
|------|-------------|
| `gateway_name` | Name of the Gateway created by this module call |
| `gateway_namespace` | Namespace where resources are deployed |

## Multiple gateways

To provision multiple gateways, call the module multiple times with unique `gateway_name` values.
All calls use the same shared namespace (`envoy-gateway-system`).

## License

[MIT License](LICENSE)
