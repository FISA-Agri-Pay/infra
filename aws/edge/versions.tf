terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "kkpp-aws-terraform-state"
    key            = "edge/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "kkpp-terraform-locks"
  }
}

# ACM certs for CloudFront and WAFv2 (scope = CLOUDFRONT) MUST live in us-east-1.
provider "aws" {
  region = "us-east-1"
}
