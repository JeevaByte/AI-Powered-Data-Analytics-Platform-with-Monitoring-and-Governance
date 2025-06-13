# Main Terraform configuration file for Data Platform

# Networking Module
module "networking" {
  source = "./modules/networking"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  domain_name         = var.domain_name
  aws_region          = var.aws_region
}

# Security Module
module "security" {
  source = "./modules/security"

  environment         = var.environment
  project_name        = var.project_name
  data_lake_bucket_id = module.storage.data_lake_bucket_id
}

# Storage Module
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

# Ingestion Module
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

# Processing Module
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

# Governance Module
module "governance" {
  source = "./modules/governance"

  environment          = var.environment
  project_name         = var.project_name
  data_lake_bucket_id  = module.storage.data_lake_bucket_id
  data_lake_bucket_arn = module.storage.data_lake_bucket_arn
  kms_key_arn          = module.security.kms_key_arn
}

# Monitoring Module
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

# Access Module
module "access" {
  source = "./modules/access"

  environment            = var.environment
  project_name           = var.project_name
  orchestrator_lambda_arn = module.processing.orchestrator_lambda_arn
  orchestrator_lambda_name = module.processing.orchestrator_lambda_name
  kms_key_arn            = module.security.kms_key_arn
  waf_web_acl_arn        = module.security.waf_web_acl_arn
}