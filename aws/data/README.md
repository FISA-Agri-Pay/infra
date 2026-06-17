# AWS Data

This layer is record-only Terraform for console-created data resources. It is
used as infrastructure documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import live RDS, DMS, KMS, or
Secrets Manager resources into this repo as part of the FinOps Inform workflow.

Confirm these cost-sensitive values in the AWS console before treating the
estimate as meaningful:

- RDS engine and engine version
- RDS instance class
- Allocated storage, storage type, backup retention, and I/O profile
- Multi-AZ and DR/read-replica topology
- DMS replication instance class and allocated storage
- DMS source and target endpoint ARNs
- Existing subnet group and security group IDs
