output "config_recorder_id" {
  description = "ID of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "lake_formation_settings_id" {
  description = "ID of the Lake Formation data lake settings"
  value       = aws_lakeformation_data_lake_settings.main.id
}