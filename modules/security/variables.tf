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