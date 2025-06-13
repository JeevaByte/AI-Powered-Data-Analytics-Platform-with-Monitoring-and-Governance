variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dataplatform"
}

variable "data_lake_bucket_id" {
  description = "ID of the data lake S3 bucket"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
}

variable "redshift_cluster_id" {
  description = "ID of the Redshift cluster"
  type        = string
}

variable "glue_job_name" {
  description = "Name of the Glue ETL job"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

variable "billing_threshold" {
  description = "Threshold for billing alarm in USD"
  type        = number
  default     = 100
}