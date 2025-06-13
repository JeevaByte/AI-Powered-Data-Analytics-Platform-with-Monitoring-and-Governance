# Processing Module - Main Configuration

# AWS Athena Database and Workgroup
resource "aws_athena_database" "main" {
  name   = "${var.environment}_${var.project_name}_db"
  bucket = var.data_lake_bucket_id
}

resource "aws_athena_workgroup" "main" {
  name = "${var.environment}-${var.project_name}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${var.data_lake_bucket_id}/athena-results/"
      
      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.kms_key_arn
      }
    }
  }

  tags = {
    Name = "${var.environment}-athena-workgroup"
  }
}

# AWS Glue DataBrew Job
resource "aws_iam_role" "databrew" {
  name = "${var.environment}-${var.project_name}-databrew-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "databrew.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-databrew-role"
  }
}

resource "aws_iam_policy" "databrew" {
  name        = "${var.environment}-${var.project_name}-databrew-policy"
  description = "Policy for DataBrew jobs"

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
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "databrew" {
  role       = aws_iam_role.databrew.name
  policy_arn = aws_iam_policy.databrew.arn
}

resource "aws_databrew_dataset" "main" {
  name = "${var.environment}-${var.project_name}-dataset"
  
  input {
    s3_input {
      path = "s3://${var.data_lake_bucket_id}/processed/"
    }
  }
}

resource "aws_databrew_recipe" "main" {
  name = "${var.environment}-${var.project_name}-recipe"
  
  steps {
    action {
      operation = "FILTER_ROW"
      parameters = {
        "pattern" = "null"
        "targetColumn" = "id"
        "value" = "false"
      }
    }
  }
}

resource "aws_databrew_job" "main" {
  name          = "${var.environment}-${var.project_name}-databrew-job"
  role_arn      = aws_iam_role.databrew.arn
  project_name  = aws_databrew_dataset.main.name
  recipe_reference {
    name = aws_databrew_recipe.main.name
  }
  
  output {
    location {
      bucket = var.data_lake_bucket_id
      key    = "refined/"
    }
  }
  
  max_capacity = 2
  max_retries  = 1
  
  tags = {
    Name = "${var.environment}-databrew-job"
  }
}

# AWS EMR Cluster
resource "aws_security_group" "emr" {
  name        = "${var.environment}-emr-sg"
  description = "Security group for EMR cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "${var.environment}-emr-sg"
  }
}

resource "aws_iam_role" "emr_service_role" {
  name = "${var.environment}-${var.project_name}-emr-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-emr-service-role"
  }
}

resource "aws_iam_role_policy_attachment" "emr_service_role" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "emr_ec2_role" {
  name = "${var.environment}-${var.project_name}-emr-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-emr-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "emr_ec2_role" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_ec2_profile" {
  name = "${var.environment}-${var.project_name}-emr-ec2-profile"
  role = aws_iam_role.emr_ec2_role.name
}

resource "aws_emr_cluster" "main" {
  name          = "${var.environment}-${var.project_name}-emr-cluster"
  release_label = "emr-6.6.0"
  applications  = ["Spark", "Hive", "Presto"]
  
  ec2_attributes {
    subnet_id                         = var.private_subnet_ids[0]
    instance_profile                  = aws_iam_instance_profile.emr_ec2_profile.arn
    emr_managed_master_security_group = aws_security_group.emr.id
    emr_managed_slave_security_group  = aws_security_group.emr.id
    service_access_security_group     = aws_security_group.emr.id
  }
  
  master_instance_group {
    instance_type = var.environment == "prod" ? "m5.xlarge" : "m5.large"
  }
  
  core_instance_group {
    instance_type  = var.environment == "prod" ? "m5.xlarge" : "m5.large"
    instance_count = var.environment == "prod" ? 2 : 1
  }
  
  service_role = aws_iam_role.emr_service_role.arn
  
  log_uri = "s3://${var.data_lake_bucket_id}/emr-logs/"
  
  configurations_json = <<EOF
[
  {
    "Classification": "spark-defaults",
    "Properties": {
      "spark.dynamicAllocation.enabled": "true",
      "spark.shuffle.service.enabled": "true"
    }
  }
]
EOF

  tags = {
    Name = "${var.environment}-emr-cluster"
  }
}

# AWS SageMaker Notebook Instance
resource "aws_security_group" "sagemaker" {
  name        = "${var.environment}-sagemaker-sg"
  description = "Security group for SageMaker notebook instance"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-sagemaker-sg"
  }
}

resource "aws_iam_role" "sagemaker" {
  name = "${var.environment}-${var.project_name}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-sagemaker-role"
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_policy" "sagemaker_s3" {
  name        = "${var.environment}-${var.project_name}-sagemaker-s3-policy"
  description = "Policy for SageMaker S3 access"

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
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_s3" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = aws_iam_policy.sagemaker_s3.arn
}

resource "aws_sagemaker_notebook_instance" "main" {
  name                    = "${var.environment}-${var.project_name}-notebook"
  role_arn                = aws_iam_role.sagemaker.arn
  instance_type           = "ml.t3.medium"
  subnet_id               = var.private_subnet_ids[0]
  security_groups         = [aws_security_group.sagemaker.id]
  kms_key_id              = var.kms_key_arn
  direct_internet_access  = false
  
  lifecycle_config_name   = aws_sagemaker_notebook_instance_lifecycle_configuration.main.name
  
  tags = {
    Name = "${var.environment}-sagemaker-notebook"
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "main" {
  name = "${var.environment}-${var.project_name}-notebook-lifecycle"
  
  on_start = base64encode(<<EOF
#!/bin/bash
set -e
echo "Starting notebook instance customization..."
pip install boto3 pandas numpy scikit-learn
EOF
  )
}

# Lambda Orchestrator
resource "aws_security_group" "lambda_orchestrator" {
  name        = "${var.environment}-lambda-orchestrator-sg"
  description = "Security group for Lambda orchestrator"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-lambda-orchestrator-sg"
  }
}

resource "aws_iam_role" "lambda_orchestrator" {
  name = "${var.environment}-${var.project_name}-lambda-orchestrator-role"

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
    Name = "${var.environment}-lambda-orchestrator-role"
  }
}

resource "aws_iam_policy" "lambda_orchestrator" {
  name        = "${var.environment}-${var.project_name}-lambda-orchestrator-policy"
  description = "Policy for Lambda orchestrator"

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
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "databrew:StartJobRun",
          "databrew:DescribeJobRun"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticmapreduce:AddJobFlowSteps",
          "elasticmapreduce:DescribeStep"
        ]
        Effect   = "Allow"
        Resource = "*"
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

resource "aws_iam_role_policy_attachment" "lambda_orchestrator" {
  role       = aws_iam_role.lambda_orchestrator.name
  policy_arn = aws_iam_policy.lambda_orchestrator.arn
}

resource "aws_lambda_function" "orchestrator" {
  function_name = "${var.environment}-${var.project_name}-orchestrator"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_orchestrator.arn
  timeout       = 300
  memory_size   = 256

  filename         = "${path.module}/lambda/orchestrator.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/orchestrator.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_orchestrator.id]
  }

  environment {
    variables = {
      GLUE_JOB_NAME    = var.glue_job_name
      DATABREW_JOB_NAME = aws_databrew_job.main.name
      EMR_CLUSTER_ID   = aws_emr_cluster.main.id
      ENVIRONMENT      = var.environment
    }
  }

  tags = {
    Name = "${var.environment}-orchestrator-lambda"
  }
}