# AWS Bastion

Record-only Terraform for the console-created RDS bastion (jump) host. Used as
infrastructure documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import the live instance.

## Recorded resource

| Resource | Value |
|---|---|
| Instance | `kkpp-rds-bastion-host` |
| Type | `t2.micro` |
| AZ | `ap-northeast-2a` |
| Purpose | SSH jump host to reach private RDS instances |

The host is normally kept **stopped** and started on demand.

## Templated / sensitive values

- `ami_id`, `subnet_id`, `security_group_ids`, `key_name` are templated
  placeholders. The real values live in the AWS console.
- SSH key material is never stored in this repo.
