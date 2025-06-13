# Root outputs for the data platform

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "data_lake_bucket_id" {
  description = "ID of the data lake S3 bucket"
  value       = module.storage.data_lake_bucket_id
}

output "redshift_endpoint" {
  description = "Endpoint of the Redshift cluster"
  value       = module.storage.redshift_endpoint
}

output "api_gateway_endpoint" {
  description = "Endpoint URL of the API Gateway"
  value       = module.access.api_gateway_endpoint
}

output "amplify_app_url" {
  description = "URL of the Amplify app"
  value       = module.access.amplify_app_url
}