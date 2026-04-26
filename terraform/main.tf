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

module "kinesis_streaming" {
  source       = "./modules/kinesis"
  environment  = var.environment
  project_name = var.project_name
}

module "lambda_processor" {
  source             = "./modules/lambda"
  project_name       = var.project_name
  environment        = var.environment
  kinesis_stream_arn = module.kinesis_streaming.stream_arn
  s3_bucket_name     = module.s3_data_lake.bucket_name
  s3_bucket_arn      = module.s3_data_lake.bucket_arn
}

module "glue_etl" {
  source         = "./modules/glue"
  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = module.s3_data_lake.bucket_name
  s3_bucket_arn  = module.s3_data_lake.bucket_arn
}

module "athena" {
  source       = "./modules/athena"
  project_name = var.project_name
  environment  = var.environment
}