output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "xray_sampling_rule_id" {
  description = "ID of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.main.id
}

output "billing_alarm_name" {
  description = "Name of the billing alarm"
  value       = aws_cloudwatch_metric_alarm.billing.alarm_name
}