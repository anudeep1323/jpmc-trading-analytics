output "dashboard_name" {
  value = aws_cloudwatch_dashboard.trading_analytics.dashboard_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.trading_alerts.arn
}