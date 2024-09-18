# Configure the AWS provider
provider "aws" {
  region = "ap-southeast-2"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

# Define Lambda functions
locals {
  lambda_functions = [
    "get_instagram_user_id",
    "get_post_comments",
    "get_user_post_ids"
  ]
  region = "ap-southeast-2"
}

# Create IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "instagram_lambda_role"

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
}

# Attach basic Lambda execution policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Create Lambda functions
resource "aws_lambda_function" "instagram_functions" {
  count = length(local.lambda_functions)

  filename      = "../lambda_functions/${local.lambda_functions[count.index]}/function.zip"
  function_name = local.lambda_functions[count.index]
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  source_code_hash = filebase64sha256("../lambda_functions/${local.lambda_functions[count.index]}/handler.py")
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "instagram_workflow" {
  name     = "instagram-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    StartAt = "GetInstagramUserId",
    States = {
      GetInstagramUserId = {
        Type     = "Task",
        Resource = aws_lambda_function.instagram_functions[0].arn,
        Next     = "GetUserPostIds"
      },
      GetUserPostIds = {
        Type     = "Task",
        Resource = aws_lambda_function.instagram_functions[2].arn,
        Next     = "GetPostComments"
      },
      GetPostComments = {
        Type     = "Task",
        Resource = aws_lambda_function.instagram_functions[1].arn,
        End      = true
      }
    }
  })
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "step_functions_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Step Functions to invoke Lambda
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "step_functions_policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.instagram_functions[*].arn
      }
    ]
  })
}

# API Gateway
resource "aws_api_gateway_rest_api" "instagram_api" {
  name = "instagram-api"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  parent_id   = aws_api_gateway_rest_api.instagram_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.instagram_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.json('$'))",
  "stateMachineArn": "${aws_sfn_state_machine.instagram_workflow.arn}"
}
EOF
  }
}

resource "aws_api_gateway_deployment" "instagram_api" {
  depends_on = [aws_api_gateway_integration.lambda]

  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  stage_name  = "prod"
}

# IAM Role for API Gateway to invoke Step Functions
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "api_gateway_policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.instagram_workflow.arn
      }
    ]
  })
}