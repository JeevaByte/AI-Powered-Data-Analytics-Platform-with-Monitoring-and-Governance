# Monitoring Module

This module provisions the monitoring resources for the data platform.

## Resources Created

- CloudWatch dashboard with metrics for Lambda, S3, Redshift, and Glue
- CloudWatch alarms for Lambda errors, Redshift CPU, and Glue job failures
- SNS topic for alerts with KMS encryption
- X-Ray sampling rule for tracing
- Billing alarm for cost monitoring

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  environment          = var.environment
  project_name         = var.project_name
  data_lake_bucket_id  = module.storage.data_lake_bucket_id
  lambda_function_name = module.ingestion.lambda_function_name
  redshift_cluster_id  = module.storage.redshift_cluster_id
  glue_job_name        = module.ingestion.glue_job_name
  kms_key_arn          = module.security.kms_key_arn
  billing_threshold    = var.billing_threshold
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | `"dataplatform"` | no |
| data_lake_bucket_id | ID of the data lake S3 bucket | `string` | n/a | yes |
| lambda_function_name | Name of the Lambda function to monitor | `string` | n/a | yes |
| redshift_cluster_id | ID of the Redshift cluster | `string` | n/a | yes |
| glue_job_name | Name of the Glue ETL job | `string` | n/a | yes |
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |
| billing_threshold | Threshold for billing alarm in USD | `number` | `100` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch_dashboard_name | Name of the CloudWatch dashboard |
| sns_topic_arn | ARN of the SNS topic for alerts |
| xray_sampling_rule_id | ID of the X-Ray sampling rule |
| billing_alarm_name | Name of the billing alarm |