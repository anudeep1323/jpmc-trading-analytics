output "data_lake_bucket" {
  description = "S3 data lake bucket name"
  value       = module.s3_data_lake.bucket_name
}

output "kinesis_stream_name" {
  description = "Kinesis stream for trade events"
  value       = module.kinesis_streaming.stream_name
}

output "lambda_function_name" {
  description = "Lambda function processing Kinesis events"
  value       = module.lambda_processor.function_name
}

output "glue_job_name" {
  description = "Glue job for bronze to silver transformation"
  value       = module.glue_etl.job_name
}

output "glue_database" {
  description = "Glue catalog database"
  value       = module.glue_etl.database_name
}

output "athena_workgroup" {
  description = "Athena workgroup for querying data"
  value       = module.athena.workgroup_name
}