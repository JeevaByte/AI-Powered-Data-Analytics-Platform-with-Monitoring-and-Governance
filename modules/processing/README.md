# Processing Module

This module provisions the data processing resources for the data platform.

## Resources Created

- Athena database and workgroup
- Glue DataBrew job, dataset, and recipe
- EMR cluster for batch processing
- SageMaker notebook instance (ml.t3.medium)
- Lambda orchestrator function for pipeline management
- IAM roles and policies for all services
- Security groups for secure network access

## Usage

```hcl
module "processing" {
  source = "./modules/processing"

  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.networking.vpc_id
  vpc_cidr             = var.vpc_cidr
  private_subnet_ids   = module.networking.private_subnet_ids
  data_lake_bucket_id  = module.storage.data_lake_bucket_id
  data_lake_bucket_arn = module.storage.data_lake_bucket_arn
  kms_key_arn          = module.security.kms_key_arn
  glue_job_name        = module.ingestion.glue_job_name
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
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |
| glue_job_name | Name of the Glue ETL job | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| athena_database_name | Name of the Athena database |
| athena_workgroup_name | Name of the Athena workgroup |
| databrew_job_name | Name of the DataBrew job |
| emr_cluster_id | ID of the EMR cluster |
| sagemaker_notebook_name | Name of the SageMaker notebook instance |
| orchestrator_lambda_arn | ARN of the orchestrator Lambda function |
| orchestrator_lambda_name | Name of the orchestrator Lambda function |