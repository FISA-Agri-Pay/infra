output "bucket_names" {
  description = "Recorded S3 bucket names by role."
  value = {
    admin_spa                = aws_s3_bucket.admin_spa.bucket
    user_spa                 = aws_s3_bucket.user_spa.bucket
    product_images           = aws_s3_bucket.product_images.bucket
    secure_credit_docs       = aws_s3_bucket.secure_credit_docs.bucket
    aiops_topology_knowledge = aws_s3_bucket.aiops_topology_knowledge.bucket
  }
}
