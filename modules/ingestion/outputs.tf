output "lambda_function_arn" {
  description = "ARN of the S3 processor Lambda function"
  value       = aws_lambda_function.s3_processor.arn
}

output "lambda_function_name" {
  description = "Name of the S3 processor Lambda function"
  value       = aws_lambda_function.s3_processor.function_name
}

output "glue_job_name" {
  description = "Name of the ETL Glue job"
  value       = aws_glue_job.etl.name
}

output "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.main.arn
}

output "msk_bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs of the MSK cluster"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  value       = aws_iam_role.glue.arn
}