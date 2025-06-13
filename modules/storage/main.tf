# Storage Module - Main Configuration

# S3 Data Lake Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.environment}-${var.project_name}-data-lake-${random_string.suffix.result}"

  tags = {
    Name = "${var.environment}-data-lake"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "archive-rule"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

# S3 Access Logs Bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-${var.project_name}-access-logs-${random_string.suffix.result}"

  tags = {
    Name = "${var.environment}-access-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "data_lake" {
  bucket        = aws_s3_bucket.data_lake.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "data-lake-logs/"
}

# DynamoDB Table for Metadata
resource "aws_dynamodb_table" "metadata" {
  name           = "${var.environment}-${var.project_name}-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "dataset_id"
  
  attribute {
    name = "dataset_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  tags = {
    Name = "${var.environment}-metadata-table"
  }
}

# Redshift Cluster
resource "aws_redshift_subnet_group" "redshift" {
  name       = "${var.environment}-redshift-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-redshift-subnet-group"
  }
}

resource "aws_security_group" "redshift" {
  name        = "${var.environment}-redshift-sg"
  description = "Security group for Redshift cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-redshift-sg"
  }
}

resource "aws_redshift_cluster" "main" {
  cluster_identifier        = "${var.environment}-${var.project_name}-redshift"
  database_name             = "dataplatform"
  master_username           = var.redshift_username
  master_password           = var.redshift_password
  node_type                 = var.environment == "prod" ? "dc2.large" : "dc2.large"
  cluster_type              = var.environment == "prod" ? "multi-node" : "single-node"
  number_of_nodes           = var.environment == "prod" ? 2 : 1
  skip_final_snapshot       = var.environment != "prod"
  automated_snapshot_retention_period = 7
  enhanced_vpc_routing      = true
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  kms_key_id                = var.kms_key_id

  tags = {
    Name = "${var.environment}-redshift-cluster"
  }
}

# AWS Backup Plan
resource "aws_backup_vault" "main" {
  name        = "${var.environment}-${var.project_name}-backup-vault"
  kms_key_arn = var.kms_key_id
  
  tags = {
    Name = "${var.environment}-backup-vault"
  }
}

resource "aws_backup_plan" "main" {
  name = "${var.environment}-${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 1 * * ? *)"
    
    lifecycle {
      delete_after = 30
    }
  }

  tags = {
    Name = "${var.environment}-backup-plan"
  }
}

resource "aws_backup_selection" "main" {
  name          = "${var.environment}-${var.project_name}-backup-selection"
  iam_role_arn  = var.backup_role_arn
  plan_id       = aws_backup_plan.main.id

  resources = [
    aws_dynamodb_table.metadata.arn
  ]
}