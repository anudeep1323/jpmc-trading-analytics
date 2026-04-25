terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "jpmc-trading-analytics"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "s3_data_lake" {
  source       = "./modules/s3"
  environment  = var.environment
  project_name = var.project_name
}