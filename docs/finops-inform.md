# FinOps Inform

## Operating rule

This repository is not the source of truth for deploying AWS resources. The live
AWS resources already exist in the console, and this repo is used for
IaC-as-documentation, Infracost estimates, and FinOps guidance.

Do not run `terraform apply` against the live environment from this repo. Do not
import live resources as part of this FinOps Inform work. The Terraform tags in
this repo are documentation, Infracost, and governance-policy inputs; actual AWS
resource tags must be applied directly in the AWS console or with AWS CLI.

## Allocation model

The current AWS architecture maps costs into these `Component` values:

- `edge`: Route 53, ACM, WAF, CloudFront, ALB, and related security groups.
- `compute`: EKS cluster, managed node group, and node IAM role.
- `network`: VPC, subnet, NAT Gateway, route table, and VPN.
- `data`: RDS, DR, DMS, KMS, Secrets Manager, and MSK.

`Environment=shared` is intentional for shared edge/network records.
`Environment=dev` is intentional for the EKS record. If Infracost Cloud
Governance only allows `Dev`, `Stage`, or `Prod`, adjust or exempt the
governance policy instead of distorting the recorded environment value.

## Forecasting

Cost forecasting is based on Terraform records in this repo and is run through
Infracost. The registered layers are:

- `aws/dns`
- `aws/edge-security`
- `aws/web-edge`
- `aws/eks`
- `aws/networking`
- `aws/data`

The `aws/finops` layer is not part of this workflow. We do not create CUR S3
buckets, CUR reports, or Cost Allocation Tag activation resources with
Terraform.

## Actual-cost bridge

Actual cost analysis uses tags on the live AWS resources, not the `.tf` files.
Apply these tags directly in AWS:

```powershell
aws resourcegroupstaggingapi tag-resources `
  --resource-arn-list <arn-1> <arn-2> `
  --tags Project=kkpp Environment=shared Service=<service> Component=<network-or-data>
```

Use the AWS Billing console or AWS CLI to activate Cost Allocation Tags for at
least `Project`, `Environment`, `Service`, and `Component`. Activation only
affects cost data after the activation point, and Cost Explorer/CUR/Athena can
lag by roughly 24 hours.

## Dashboard

The Grafana dashboard at
`aws/observability/grafana/dashboards/finops-inform-cost-dashboard.json` assumes
CUR to Athena or a compatible Cost Explorer/Athena data model. The Athena
datasource UID is left as the `${DS_ATHENA}` template variable, and the
`cur_database` and `cur_table` variables must be set to the real CUR database
and table before use.

## Current PR scope

Handled here:

- CloudFront WAF false-positive estimates are addressed through `infracost.yml`
  variables for the real web-edge aliases, ACM certificate, and WAF ARN.
- `catalog_api_alb` VPC origin tag documentation is aligned with the other VPC
  origins.
- S3/CUR Terraform is not created, so S3 CUR governance findings are not
  applicable to this workflow.
- `Environment=shared` governance findings should be handled by policy
  adjustment or exception.

Not handled here:

- EKS `t3.medium` to `t4g.medium`; Graviton/ARM needs separate validation.
- ALB HTTP to HTTPS redirect; this can change behavior in the current internal
  ALB and CloudFront VPC Origin design and should be tracked as a separate
  security design issue.
