output "data_lake_bucket" {
  description = "S3 data lake bucket name"
  value       = module.s3_data_lake.bucket_name
}