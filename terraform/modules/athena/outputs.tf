output "workgroup_name" {
  value = aws_athena_workgroup.trading.name
}

output "results_bucket" {
  value = aws_s3_bucket.athena_results.bucket
}