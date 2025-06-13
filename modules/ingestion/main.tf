# Ingestion Module - Main Configuration

# Lambda Function for S3 Uploads
resource "aws_security_group" "lambda" {
  name        = "${var.environment}-lambda-ingestion-sg"
  description = "Security group for Lambda ingestion functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-lambda-ingestion-sg"
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.environment}-${var.project_name}-lambda-ingestion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-lambda-ingestion-role"
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.environment}-${var.project_name}-lambda-ingestion-policy"
  description = "Policy for Lambda ingestion functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "${var.data_lake_bucket_arn}",
          "${var.data_lake_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = var.metadata_table_arn
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "s3_processor" {
  function_name = "${var.environment}-${var.project_name}-s3-processor"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda.arn
  timeout       = 60
  memory_size   = 256

  filename         = "${path.module}/lambda/s3_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/s3_processor.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      METADATA_TABLE = var.metadata_table_name
      ENVIRONMENT    = var.environment
    }
  }

  tags = {
    Name = "${var.environment}-s3-processor-lambda"
  }
}

resource "aws_s3_bucket_notification" "data_lake" {
  bucket = var.data_lake_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
  }
}

resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.data_lake_bucket_id}"
}

# AWS Glue Job
resource "aws_iam_role" "glue" {
  name = "${var.environment}-${var.project_name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-glue-role"
  }
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "glue" {
  name        = "${var.environment}-${var.project_name}-glue-policy"
  description = "Policy for Glue jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "${var.data_lake_bucket_arn}",
          "${var.data_lake_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = var.metadata_table_arn
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue.arn
}

resource "aws_glue_job" "etl" {
  name     = "${var.environment}-${var.project_name}-etl-job"
  role_arn = aws_iam_role.glue.arn
  
  command {
    name            = "glueetl"
    script_location = "s3://${var.data_lake_bucket_id}/scripts/etl_job.py"
    python_version  = "3"
  }
  
  default_arguments = {
    "--job-language"             = "python"
    "--enable-metrics"           = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                  = "s3://${var.data_lake_bucket_id}/temp/"
    "--metadata_table"           = var.metadata_table_name
    "--environment"              = var.environment
  }
  
  max_retries      = 1
  timeout          = 60
  worker_type      = "G.1X"
  number_of_workers = 2
  
  execution_property {
    max_concurrent_runs = 1
  }
  
  tags = {
    Name = "${var.environment}-etl-job"
  }
}

# Amazon MSK Cluster
resource "aws_security_group" "msk" {
  name        = "${var.environment}-msk-sg"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
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
    Name = "${var.environment}-msk-sg"
  }
}

resource "aws_msk_configuration" "msk" {
  name              = "${var.environment}-${var.project_name}-msk-config"
  kafka_versions    = ["2.8.1"]
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
delete.topic.enable=true
PROPERTIES
}

resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.environment}-${var.project_name}-msk"
  kafka_version          = "2.8.1"
  number_of_broker_nodes = var.environment == "prod" ? 3 : 2

  broker_node_group_info {
    instance_type   = var.environment == "prod" ? "kafka.m5.large" : "kafka.t3.small"
    client_subnets  = var.private_subnet_ids
    security_groups = [aws_security_group.msk.id]
    
    storage_info {
      ebs_storage_info {
        volume_size = var.environment == "prod" ? 100 : 20
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
    encryption_at_rest_kms_key_arn = var.kms_key_arn
  }

  configuration_info {
    arn      = aws_msk_configuration.msk.arn
    revision = 1
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  tags = {
    Name = "${var.environment}-msk-cluster"
  }
}

resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.environment}-${var.project_name}"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.environment}-msk-logs"
  }
}