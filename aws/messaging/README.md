# AWS Messaging (SQS)

Record-only Terraform for console-created SQS queues. Used as infrastructure
documentation and Infracost input only.

Do not run `terraform apply` for this layer. Do not import the live queues.

## Recorded queues

All queues are FIFO with 14-day message retention and default SSE-SQS encryption.

| Queue | Type | Visibility timeout | Redrive |
|---|---|---|---|
| `credit-payment-requested.fifo` | main | 120s | → DLQ, maxReceiveCount 5 |
| `credit-payment-requested-dlq.fifo` | DLQ | 30s | — |
| `payment-pin-verified.fifo` | main | 120s | → DLQ, maxReceiveCount 5 |
| `payment-pin-verified-dlq.fifo` | DLQ | 30s | — |

Message contents and producer/consumer credentials are not stored in this repo.
