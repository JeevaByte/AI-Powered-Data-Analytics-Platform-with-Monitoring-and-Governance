# Access Module

This module provisions the access layer resources for the data platform.

## Resources Created

- API Gateway REST API with Lambda integration
- API Gateway resources, methods, and deployments
- API Gateway usage plan and API key
- CloudWatch log group for API Gateway
- Cognito user pool and client for authentication
- API Gateway authorizer using Cognito
- Amplify app for frontend deployment
- IAM role for QuickSight Redshift access

## Usage

```hcl
module "access" {
  source = "./modules/access"

  environment            = var.environment
  project_name           = var.project_name
  orchestrator_lambda_arn = module.processing.orchestrator_lambda_arn
  orchestrator_lambda_name = module.processing.orchestrator_lambda_name
  kms_key_arn            = module.security.kms_key_arn
  waf_web_acl_arn        = module.security.waf_web_acl_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | `"dataplatform"` | no |
| orchestrator_lambda_arn | ARN of the orchestrator Lambda function | `string` | n/a | yes |
| orchestrator_lambda_name | Name of the orchestrator Lambda function | `string` | n/a | yes |
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |
| waf_web_acl_arn | ARN of the WAF web ACL | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| api_gateway_id | ID of the API Gateway REST API |
| api_gateway_endpoint | Endpoint URL of the API Gateway |
| cognito_user_pool_id | ID of the Cognito user pool |
| cognito_client_id | ID of the Cognito user pool client |
| amplify_app_id | ID of the Amplify app |
| amplify_app_url | Default URL of the Amplify app |