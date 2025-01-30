terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Configure backend for state storage
  backend "s3" {
    bucket         = "atoma-state-bucket"
    key            = "atoma/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock" # Optional: for state locking
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "atoma"
      ManagedBy   = "terraform"
    }
  }
}
