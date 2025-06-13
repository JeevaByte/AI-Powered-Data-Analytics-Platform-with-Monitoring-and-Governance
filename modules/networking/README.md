# Networking Module

This module provisions the core networking infrastructure for the data platform.

## Resources Created

- VPC with CIDR block 10.0.0.0/16
- Public and private subnets across 2 AZs
- Internet Gateway for public internet access
- NAT Gateway for private subnet outbound access
- Route tables for public and private subnets
- Route 53 private hosted zone
- Security groups for various services
- S3 VPC endpoint for private S3 access

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["eu-west-2a", "eu-west-2b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  domain_name         = "dataplatform.internal"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| availability_zones | List of availability zones to use | `list(string)` | n/a | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | n/a | yes |
| domain_name | Private hosted zone domain name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| private_subnet_ids | List of private subnet IDs |
| public_subnet_ids | List of public subnet IDs |
| lambda_security_group_id | ID of the Lambda security group |
| s3_endpoint_id | ID of the S3 VPC endpoint |
| route53_zone_id | ID of the private hosted zone |