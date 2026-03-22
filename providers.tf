provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NeoPay"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
