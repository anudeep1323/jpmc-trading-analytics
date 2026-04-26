output "database_name" {
  value = aws_glue_catalog_database.trading.name
}

output "job_name" {
  value = aws_glue_job.bronze_to_silver.name
}

output "role_arn" {
  value = aws_iam_role.glue_role.arn
}