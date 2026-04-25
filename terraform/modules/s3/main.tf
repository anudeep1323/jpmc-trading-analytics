resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-datalake-${var.environment}"
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create the 3 zones as folders
resource "aws_s3_object" "bronze" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "bronze/"
  content = ""
}

resource "aws_s3_object" "silver" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "silver/"
  content = ""
}

resource "aws_s3_object" "gold" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "gold/"
  content = ""
}