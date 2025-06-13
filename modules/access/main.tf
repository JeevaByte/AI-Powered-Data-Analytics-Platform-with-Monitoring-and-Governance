# Access Module - Main Configuration

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.environment}-${var.project_name}-api"
  description = "API Gateway for Data Platform"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = {
    Name = "${var.environment}-api-gateway"
  }
}

# API Gateway Resource and Method
resource "aws_api_gateway_resource" "data" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "data"
}

resource "aws_api_gateway_method" "get_data" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.data.id
  http_method   = "GET"
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.main.id
  
  request_parameters = {
    "method.request.querystring.dataset" = true
  }
}

resource "aws_api_gateway_integration" "get_data" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.data.id
  http_method             = aws_api_gateway_method.get_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.orchestrator_lambda_arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.orchestrator_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/${aws_api_gateway_method.get_data.http_method}${aws_api_gateway_resource.data.path}"
}

# API Gateway Deployment and Stage
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.data.id,
      aws_api_gateway_method.get_data.id,
      aws_api_gateway_integration.get_data.id
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [aws_api_gateway_integration.get_data]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  
  tags = {
    Name = "${var.environment}-api-stage"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.main.name}"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn
  
  tags = {
    Name = "${var.environment}-api-gateway-logs"
  }
}

# API Gateway WAF Association
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}

# API Gateway Usage Plan and API Key
resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.environment}-${var.project_name}-usage-plan"
  description = "Usage plan for Data Platform API"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }
  
  quota_settings {
    limit  = 1000
    period = "DAY"
  }
  
  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
  
  tags = {
    Name = "${var.environment}-usage-plan"
  }
}

resource "aws_api_gateway_api_key" "main" {
  name = "${var.environment}-${var.project_name}-api-key"
  
  tags = {
    Name = "${var.environment}-api-key"
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-${var.project_name}-user-pool"
  
  username_attributes      = ["email"]
  auto_verify_attributes   = ["email"]
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }
  
  tags = {
    Name = "${var.environment}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name                = "${var.environment}-${var.project_name}-client"
  user_pool_id        = aws_cognito_user_pool.main.id
  
  generate_secret     = true
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_api_gateway_authorizer" "main" {
  name          = "${var.environment}-${var.project_name}-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]
}

# AWS Amplify App
resource "aws_amplify_app" "main" {
  name       = "${var.environment}-${var.project_name}-app"
  repository = "https://github.com/example/data-platform-frontend"
  
  # For demo purposes, using default access token
  # In production, use GitHub OIDC or other secure methods
  access_token = "github_access_token_placeholder"
  
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
  
  environment_variables = {
    API_ENDPOINT = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
    USER_POOL_ID = aws_cognito_user_pool.main.id
    CLIENT_ID    = aws_cognito_user_pool_client.main.id
  }
  
  tags = {
    Name = "${var.environment}-amplify-app"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = "main"
  
  framework = "React"
  stage     = var.environment
  
  tags = {
    Name = "${var.environment}-amplify-branch"
  }
}

# QuickSight
resource "aws_iam_role" "quicksight" {
  name = "${var.environment}-${var.project_name}-quicksight-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-quicksight-role"
  }
}

resource "aws_iam_policy" "quicksight_redshift" {
  name        = "${var.environment}-${var.project_name}-quicksight-redshift-policy"
  description = "Policy for QuickSight to access Redshift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "quicksight_redshift" {
  role       = aws_iam_role.quicksight.name
  policy_arn = aws_iam_policy.quicksight_redshift.arn
}

data "aws_region" "current" {}