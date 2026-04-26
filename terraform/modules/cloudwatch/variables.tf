variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address for alerts"
}