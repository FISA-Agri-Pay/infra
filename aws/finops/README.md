# FinOps Inform

This layer activates cost allocation tags and provisions Cost and Usage Reports
for actual-cost analysis.

## Apply order

1. Apply this layer early so `Project`, `Service`, `Environment`, and
   `Component` become active billing tags.
2. Wait for AWS Billing propagation. Cost allocation tags usually take about
   24 hours and only affect cost data after activation.
3. Configure Grafana's Athena data source with the CUR database/table generated
   by the AWS CUR Athena integration.

NAT, RDS, DMS, and DR resources are currently outside this Terraform repo. Tag
those live resources directly with the same keys, or import/code them in the
follow-up data/networking PR so they flow into the same allocation model.
