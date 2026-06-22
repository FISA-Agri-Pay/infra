# AWS Alerting (CloudWatch → Slack)

Record-only Terraform for the console-created CloudWatch alerting stack on the
EKS cluster. Used as infrastructure documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import the live resources.

## Flow

```text
CloudWatch alarms ──► SNS topic ──► Lambda (python3.12) ──► Slack webhook
```

## Recorded resources

| Resource | Name |
|---|---|
| SNS topic | `eks-kkpp-eks-k8s-cloudwatch-alerts` |
| Lambda | `eks-kkpp-eks-cloudwatch-slack-alerts` |
| Lambda role | `eks-kkpp-eks-cloudwatch-slack-lambda-role` |
| Secret | `eks/kkpp-eks/cloudwatch/slack-webhook` |

## Templated / sensitive values

- The **Slack webhook URL** is never stored here — only the Secrets Manager
  container is recorded.
- The **Lambda function code** is not committed; `lambda_package_path` points at
  a placeholder zip.
- Lambda execution-role policies (CloudWatch Logs + `secretsmanager:GetSecretValue`)
  are managed in the console and not reproduced here.
