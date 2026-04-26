# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-results-${var.environment}"
}

# Athena workgroup
resource "aws_athena_workgroup" "trading" {
  name = "${var.project_name}-workgroup-${var.environment}"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"
    }
    
    enforce_workgroup_configuration = true
  }
}