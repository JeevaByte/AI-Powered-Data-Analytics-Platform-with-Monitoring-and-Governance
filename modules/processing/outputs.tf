output "athena_database_name" {
  description = "Name of the Athena database"
  value       = aws_athena_database.main.name
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "databrew_job_name" {
  description = "Name of the DataBrew job"
  value       = aws_databrew_job.main.name
}

output "emr_cluster_id" {
  description = "ID of the EMR cluster"
  value       = aws_emr_cluster.main.id
}

output "sagemaker_notebook_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.main.name
}

output "orchestrator_lambda_arn" {
  description = "ARN of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.arn
}

output "orchestrator_lambda_name" {
  description = "Name of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.function_name
}