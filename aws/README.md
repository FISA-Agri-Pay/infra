# AWS

AWS infrastructure configuration for EKS, MSK, networking, and monitoring.

## Directories

- `eks/`: EKS cluster and add-on configuration
- `msk/`: Kafka/MSK configuration (planned; not yet provisioned)
- `networking/`: VPC, subnet, routing, VPN, and security group configuration
- `monitoring/`: observability configuration (Helm releases)
- `data/`: RDS, DMS, KMS, and Secrets Manager records
- `dns/`: Route 53 zone, records, and ACM validation
- `edge-security/`: ACM certificate and WAFv2 web ACL
- `web-edge/`: CloudFront distribution and the admin-api ALB
- `storage/`: S3 buckets
- `ecr/`: container image registries
- `messaging/`: SQS queues
- `alerting/`: CloudWatch alarms + SNS → Lambda → Slack alert stack
- `bastion/`: RDS bastion (jump) host

> All AWS layers are **record-only** Terraform: documentation and Infracost
> input for console-created resources. Do not `apply` or `import` them.
