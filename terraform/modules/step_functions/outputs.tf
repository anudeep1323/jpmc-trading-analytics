output "state_machine_arn" {
  value = aws_sfn_state_machine.daily_etl.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.daily_etl.name
}

output "schedule_rule_name" {
  value = aws_cloudwatch_event_rule.daily_etl_schedule.name
}