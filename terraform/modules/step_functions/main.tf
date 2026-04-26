# IAM role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-step-functions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# Policy to start Glue jobs
resource "aws_iam_role_policy" "step_functions_glue" {
  name = "step-functions-glue-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step Functions state machine for daily ETL
resource "aws_sfn_state_machine" "daily_etl" {
  name     = "${var.project_name}-daily-etl-${var.environment}"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Daily ETL workflow: Bronze to Silver transformation"
    StartAt = "RunGlueJob"
    States = {
      RunGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_name
        }
        Next = "CheckJobStatus"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "JobFailed"
        }]
      }
      CheckJobStatus = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.JobRunState"
          StringEquals  = "SUCCEEDED"
          Next          = "JobSucceeded"
        }]
        Default = "JobFailed"
      }
      JobSucceeded = {
        Type = "Succeed"
      }
      JobFailed = {
        Type = "Fail"
        Error = "GlueJobFailed"
        Cause = "The Glue ETL job failed"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/states/${var.project_name}-daily-etl-${var.environment}"
  retention_in_days = 7
}

# EventBridge rule to trigger Step Functions daily at 2 AM
resource "aws_cloudwatch_event_rule" "daily_etl_schedule" {
  name                = "${var.project_name}-daily-etl-schedule-${var.environment}"
  description         = "Trigger daily ETL at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

# EventBridge target - Step Functions
resource "aws_cloudwatch_event_target" "step_functions_target" {
  rule      = aws_cloudwatch_event_rule.daily_etl_schedule.name
  target_id = "StepFunctionsTarget"
  arn       = aws_sfn_state_machine.daily_etl.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# IAM role for EventBridge to invoke Step Functions
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-eventbridge-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_step_functions" {
  name = "eventbridge-step-functions-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "states:StartExecution"
      ]
      Resource = aws_sfn_state_machine.daily_etl.arn
    }]
  })
}


# Policy to write logs to CloudWatch
resource "aws_iam_role_policy" "step_functions_logs" {
  name = "step-functions-logs-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}