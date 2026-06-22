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

## CloudWatch alarms (`alarms.tf`)

Recorded alarms that drive (or relate to) this stack:

| Alarm group | Metric | Threshold | Action |
|---|---|---|---|
| EKS deployment replicas unavailable | `status_replicas_unavailable` | ≥ 1 (10×60s) | → SNS |
| EKS node not ready (per node) | `node_status_condition_ready` | < 1 (3×60s) | → SNS |
| EKS node root FS almost full (per node) | `node_filesystem_utilization` | > 85% (10×60s) | → SNS |
| SQS visible messages | `ApproximateNumberOfMessagesVisible` | > 100 (5×60s) | none wired |
| SQS oldest message age | `ApproximateAgeOfOldestMessage` | > 300s (5×60s) | none wired |
| SQS DLQ visible messages | `ApproximateNumberOfMessagesVisible` | ≥ 1 (1×60s) | none wired |

Notes:
- Per-node alarms are auto-created per worker node by the
  `amazon-cloudwatch-observability` addon; `eks_nodes` holds templated
  placeholders (node names / instance IDs are ephemeral).
- The cluster/pod-level **recommended alarms** (PVC problem, pod not healthy,
  pod restart high, pod waiting) are metric-math expression alarms managed by
  the same addon and are **not** reproduced as Terraform here.
- The SQS alarms currently have **no notification action** wired (recorded as-is).

## Templated / sensitive values

- The **Slack webhook URL** is never stored here — only the Secrets Manager
  container is recorded.
- The **Lambda function code** is not committed; `lambda_package_path` points at
  a placeholder zip.
- Lambda execution-role policies (CloudWatch Logs + `secretsmanager:GetSecretValue`)
  are managed in the console and not reproduced here.
