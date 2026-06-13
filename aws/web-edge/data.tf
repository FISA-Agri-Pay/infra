# AWS-managed prefix list of CloudFront origin-facing IP ranges.
# Used to restrict the internal ALB security groups to CloudFront only.
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Internal ALBs that are managed outside this module (by the EKS/app stack)
# but consumed here as CloudFront VPC origins.
data "aws_lb" "aiops_api" {
  name = "kkpp-aiops-api"
}

data "aws_lb" "catalog_api" {
  name = "kkpp-service-catalog-api"
}
