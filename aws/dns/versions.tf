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
    key            = "dns/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "kkpp-terraform-locks"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# The ACM certificate lives in us-east-1, so its validation resource needs a
# us-east-1 provider.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
