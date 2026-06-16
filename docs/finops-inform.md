# FinOps Inform

## Allocation model

The current AWS architecture maps costs into these `Component` values:

- `edge`: Route 53, ACM, WAF, CloudFront, ALB, and related security groups.
- `compute`: EKS cluster, managed node group, node IAM role, and propagated
  worker ASG tags.
- `network`: NAT gateways, routing, VPN, and VPC resources. These are live but
  not yet managed by this repo.
- `data`: RDS, DR standby, DMS, KMS, Secrets Manager, and future MSK resources.
  These are live but not yet managed by this repo.
- `finops`: Cost allocation tag activation and CUR delivery resources.

## Actual-cost bridge for resources outside Terraform

NAT, RDS, DMS, and DR resources must be tagged directly until they are imported
or codified in the follow-up networking/data PR:

```powershell
aws resourcegroupstaggingapi tag-resources `
  --resource-arn-list <arn-1> <arn-2> `
  --tags Project=kkpp Environment=shared Service=<service> Component=<network-or-data>
```

After `aws/finops` is applied, AWS Billing will start collecting the activated
tag keys from that point forward. Expect roughly 24 hours before Cost Explorer,
CUR, and Athena queries expose the new split.
