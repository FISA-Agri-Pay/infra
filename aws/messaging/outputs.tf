output "queue_names" {
  description = "Recorded SQS queue names (FIFO main + DLQ pairs)."
  value = {
    credit_payment_requested     = aws_sqs_queue.credit_payment_requested.name
    credit_payment_requested_dlq = aws_sqs_queue.credit_payment_requested_dlq.name
    payment_pin_verified         = aws_sqs_queue.payment_pin_verified.name
    payment_pin_verified_dlq     = aws_sqs_queue.payment_pin_verified_dlq.name
  }
}
