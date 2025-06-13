environment = "staging"
project_name = "dataplatform"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-west-2a", "eu-west-2b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
domain_name = "staging.dataplatform.internal"

# Redshift Configuration
redshift_username = "admin"
redshift_password = "StagingPassword123!" # Change in production

# Monitoring Configuration
billing_threshold = 100