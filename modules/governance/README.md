# Governance Module

This module provisions the governance resources for the data platform.

## Resources Created

- AWS Config configuration recorder and delivery channel
- AWS Config rules for S3 bucket versioning, encrypted volumes, and IAM password policy
- AWS Lake Formation data lake settings and resource registration
- IAM roles and policies for AWS Config

## Usage

```hcl
module "governance" {
  source = "./modules/governance"

  environment          = var.environment
  project_name         = var.project_name
  data_lake_bucket_id  = module.storage.data_lake_bucket_id
  data_lake_bucket_arn = module.storage.data_lake_bucket_arn
  kms_key_arn          = module.security.kms_key_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | `"dataplatform"` | no |
| data_lake_bucket_id | ID of the data lake S3 bucket | `string` | n/a | yes |
| data_lake_bucket_arn | ARN of the data lake S3 bucket | `string` | n/a | yes |
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| config_recorder_id | ID of the AWS Config configuration recorder |
| lake_formation_settings_id | ID of the Lake Formation data lake settings |