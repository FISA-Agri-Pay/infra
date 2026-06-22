# AWS ECR

Record-only Terraform for console-created ECR repositories. Used as
infrastructure documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import the live repositories.

## Recorded repositories

| Repository | Tag mutability | Scan on push | Encryption |
|---|---|---|---|
| `service-catalog` | MUTABLE | off | AES256 |
| `kkpp/mcp-aiops-backend` | IMMUTABLE | off | AES256 |

Image contents and pull/push credentials are not stored in this repo.
