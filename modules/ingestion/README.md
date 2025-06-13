# Ingestion Module

This module provisions the data ingestion resources for the data platform.

## Resources Created

- Lambda function triggered by S3 uploads
- IAM roles and policies for Lambda
- S3 bucket notification configuration
- Glue ETL job for data processing
- IAM roles and policies for Glue
- MSK Kafka cluster with broker nodes
- Security groups for MSK and Lambda
- CloudWatch log groups for monitoring

## Usage

```hcl
module "ingestion" {
  source = "./modules/ingestion"

  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.networking.vpc_id
  vpc_cidr             = var.vpc_cidr
  private_subnet_ids   = module.networking.private_subnet_ids
  data_lake_bucket_id  = module.storage.data_lake_bucket_id
  data_lake_bucket_arn = module.storage.data_lake_bucket_arn
  metadata_table_name  = module.storage.metadata_table_name
  metadata_table_arn   = module.storage.metadata_table_arn
  kms_key_arn          = module.security.kms_key_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | `"dataplatform"` | no |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| vpc_cidr | CIDR block of the VPC | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| data_lake_bucket_id | ID of the data lake S3 bucket | `string` | n/a | yes |
| data_lake_bucket_arn | ARN of the data lake S3 bucket | `string` | n/a | yes |
| metadata_table_name | Name of the DynamoDB metadata table | `string` | n/a | yes |
| metadata_table_arn | ARN of the DynamoDB metadata table | `string` | n/a | yes |
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | ARN of the S3 processor Lambda function |
| lambda_function_name | Name of the S3 processor Lambda function |
| glue_job_name | Name of the ETL Glue job |
| msk_cluster_arn | ARN of the MSK cluster |
| msk_bootstrap_brokers_tls | TLS connection host:port pairs of the MSK cluster |
| lambda_role_arn | ARN of the Lambda IAM role |
| glue_role_arn | ARN of the Glue IAM role |