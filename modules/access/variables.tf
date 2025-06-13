variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dataplatform"
}

variable "orchestrator_lambda_arn" {
  description = "ARN of the orchestrator Lambda function"
  type        = string
}

variable "orchestrator_lambda_name" {
  description = "Name of the orchestrator Lambda function"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL"
  type        = string
}