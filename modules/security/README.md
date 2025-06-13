# Security Module

This module provisions the security resources for the data platform.

## Resources Created

- KMS key for encryption with automatic rotation
- KMS alias for easy reference
- AWS Backup IAM role
- CloudTrail with multi-region logging
- S3 bucket for CloudTrail logs with encryption
- GuardDuty detector
- WAF web ACL for API Gateway protection

## Usage

```hcl
module "security" {
  source = "./modules/security"

  environment         = var.environment
  project_name        = var.project_name
  data_lake_bucket_id = module.storage.data_lake_bucket_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | `"dataplatform"` | no |
| data_lake_bucket_id | ID of the data lake S3 bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_id | ID of the KMS key |
| kms_key_arn | ARN of the KMS key |
| backup_role_arn | ARN of the AWS Backup IAM role |
| cloudtrail_id | ID of the CloudTrail trail |
| guardduty_detector_id | ID of the GuardDuty detector |
| waf_web_acl_id | ID of the WAF web ACL |
| waf_web_acl_arn | ARN of the WAF web ACL |