# Storage Module

This module provisions the storage resources for the data platform.

## Resources Created

- S3 data lake bucket with versioning, encryption, and lifecycle rules
- S3 access logs bucket with encryption
- DynamoDB table for metadata with dataset_id as partition key
- Redshift cluster with enhanced VPC routing
- AWS Backup plan for data protection

## Usage

```hcl
module "storage" {
  source = "./modules/storage"

  environment         = var.environment
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.networking.private_subnet_ids
  kms_key_id          = module.security.kms_key_arn
  redshift_username   = var.redshift_username
  redshift_password   = var.redshift_password
  backup_role_arn     = module.security.backup_role_arn
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
| kms_key_id | KMS key ID for encryption | `string` | n/a | yes |
| redshift_username | Redshift master username | `string` | n/a | yes |
| redshift_password | Redshift master password | `string` | n/a | yes |
| backup_role_arn | IAM role ARN for AWS Backup | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| data_lake_bucket_id | ID of the data lake S3 bucket |
| data_lake_bucket_arn | ARN of the data lake S3 bucket |
| metadata_table_name | Name of the DynamoDB metadata table |
| metadata_table_arn | ARN of the DynamoDB metadata table |
| redshift_cluster_id | ID of the Redshift cluster |
| redshift_endpoint | Endpoint of the Redshift cluster |
| redshift_security_group_id | ID of the Redshift security group |