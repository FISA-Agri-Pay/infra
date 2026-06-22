# Record-only Terraform for live console-created SQS queues.
# This is an IaC documentation and Infracost input layer. Do not apply it.
#
# Two FIFO domain events, each paired with a dead-letter queue. Message bodies
# and credentials are never stored in this repo.

locals {
  common_tags = {
    Project     = "kkpp"
    ManagedBy   = "terraform"
    Environment = "shared"
    Service     = "messaging"
    Component   = "sqs"
  }
}

# --- credit-payment-requested ---
resource "aws_sqs_queue" "credit_payment_requested_dlq" {
  name                        = "credit-payment-requested-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  visibility_timeout_seconds  = 30
  message_retention_seconds   = var.message_retention_seconds

  tags = merge(local.common_tags, { Name = "credit-payment-requested-dlq", Role = "dlq" })
}

resource "aws_sqs_queue" "credit_payment_requested" {
  name                        = "credit-payment-requested.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  visibility_timeout_seconds  = 120
  message_retention_seconds   = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.credit_payment_requested_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(local.common_tags, { Name = "credit-payment-requested", Role = "main" })
}

# --- payment-pin-verified ---
resource "aws_sqs_queue" "payment_pin_verified_dlq" {
  name                        = "payment-pin-verified-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  visibility_timeout_seconds  = 30
  message_retention_seconds   = var.message_retention_seconds

  tags = merge(local.common_tags, { Name = "payment-pin-verified-dlq", Role = "dlq" })
}

resource "aws_sqs_queue" "payment_pin_verified" {
  name                        = "payment-pin-verified.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  visibility_timeout_seconds  = 120
  message_retention_seconds   = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_pin_verified_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(local.common_tags, { Name = "payment-pin-verified", Role = "main" })
}
