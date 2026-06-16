output "cur_bucket_name" {
  description = "S3 bucket receiving Cost and Usage Reports."
  value       = aws_s3_bucket.cur.bucket
}

output "cur_report_name" {
  description = "Cost and Usage Report name."
  value       = aws_cur_report_definition.kkpp.report_name
}
