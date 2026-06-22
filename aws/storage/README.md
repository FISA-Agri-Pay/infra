# AWS Storage (S3)

Record-only Terraform for console-created S3 buckets. Used as infrastructure
documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import the live buckets.

## Recorded buckets

| Bucket | Role | Encryption | Notes |
|---|---|---|---|
| `kkpp-admin-s3-bucket` | Admin SPA static site | AES256 | CloudFront origin (website endpoint), SPA fallback to `index.html` |
| `kkpp-s3-bucket` | User SPA static site | AES256 | CloudFront origin (website endpoint), SPA fallback to `index.html` |
| `kkpp-product-images` | Product image assets | AES256 | |
| `kkpp-secure-credit-docs-bucket` | Secure credit documents | aws:kms (customer key) | Public access fully blocked |
| `kkpp-aiops-topology-knowledge-<account>-<region>` | AIOps knowledge store | AES256 | Versioning enabled |

## Templated / sensitive values

- `account_id` defaults to `000000000000`. The real account ID is part of the
  AIOps bucket name; replace it in the console or via `-var` if the name must
  resolve.
- `secure_docs_kms_key_arn` is a templated placeholder. The real customer-managed
  KMS key ARN lives in the AWS console / `data` layer.
- No bucket policies, object contents, or credentials are stored in this repo.

## Out of scope (intentionally not recorded)

- `kkpp-aws-terraform-state` — Terraform state backend bucket (bootstrap).
