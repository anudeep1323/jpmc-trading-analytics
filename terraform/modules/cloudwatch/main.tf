# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "trading_analytics" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Kinesis", "IncomingRecords", { stat = "Sum", label = "Trades Received" }],
            [".", "IncomingBytes", { stat = "Sum", label = "Data Volume" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Kinesis Stream - Trading Activity"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Lambda Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Duration", { stat = "Average", label = "Avg Duration (ms)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda - Processing Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Glue", "glue.driver.aggregate.numCompletedTasks", { stat = "Sum" }],
            [".", "glue.driver.aggregate.numFailedTasks", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Glue ETL - Job Status"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '/aws/lambda/${var.lambda_function_name}' | fields @timestamp, @message | filter @message like /LARGE TRADE ALERT/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Large Trade Alerts (Last 20)"
        }
      }
    ]
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "trading_alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.trading_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when Lambda has more than 5 errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.trading_alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }
}

# CloudWatch Alarm - Glue Job Failures
resource "aws_cloudwatch_metric_alarm" "glue_failures" {
  alarm_name          = "${var.project_name}-glue-failures-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "AWS/Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Glue job has failed tasks"
  alarm_actions       = [aws_sns_topic.trading_alerts.arn]
}

# Metric filter for large trades
resource "aws_cloudwatch_log_metric_filter" "large_trades" {
  name           = "${var.project_name}-large-trades-${var.environment}"
  log_group_name = "/aws/lambda/${var.lambda_function_name}"
  pattern = "LARGE TRADE ALERT"

  metric_transformation {
    name      = "LargeTradeCount"
    namespace = "TradingPlatform"
    value     = "1"
  }
}

# Alarm for large trades
resource "aws_cloudwatch_metric_alarm" "large_trades_alarm" {
  alarm_name          = "${var.project_name}-large-trades-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "LargeTradeCount"
  namespace           = "TradingPlatform"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alert when more than 3 large trades in 1 minute"
  alarm_actions       = [aws_sns_topic.trading_alerts.arn]
  treat_missing_data  = "notBreaching"
}