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

# Create a Lambda Layer
resource "aws_lambda_layer_version" "common_layer" {
  filename          = "${path.module}/../lambda_layers/common_layer/layer.zip"
  layer_name        = "common_layer"
  compatible_runtimes = ["python3.11"]

  source_code_hash = filebase64sha256("${path.module}/../lambda_layers/common_layer/layer.zip")
}

# Create Lambda functions
resource "aws_lambda_function" "instagram_functions" {
  count = length(local.lambda_functions)

  filename      = "../lambda_functions/${local.lambda_functions[count.index]}/function.zip"
  function_name = local.lambda_functions[count.index]
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  environment {
    variables = {
      HIKER_API_KEY = var.hiker_api_key
      ANTHROPIC_API_KEY = var.anthropic_api_key
    }
  }

  source_code_hash = filebase64sha256("../lambda_functions/${local.lambda_functions[count.index]}/handler.py")

  layers = [aws_lambda_layer_version.common_layer.arn]
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "instagram_workflow" {
  name     = "instagram-workflow"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "EXPRESS"

  definition = jsonencode({
  "StartAt": "GetInstagramUserId",
  "States": {
    "GetInstagramUserId": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-southeast-2:451063387247:function:get_instagram_user_id",
      "Next": "GetUserPostIds",
      "InputPath": "$",
      "ResultPath": "$.user_id"
    },
    "GetUserPostIds": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-southeast-2:451063387247:function:get_user_post_ids",
      "Next": "GetPostComments",
      "ResultPath": "$.post_ids"
    },
    "GetPostComments": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-southeast-2:451063387247:function:get_post_comments",
      "End": true,
      "ResultPath": "$.comments",
      "OutputPath": "$.comments"
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

resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartSyncExecution"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.body)",
  "stateMachineArn": "${aws_sfn_state_machine.instagram_workflow.arn}"
}
EOF
  }
}

# Integration response for HTTP 400 error
resource "aws_api_gateway_integration_response" "bad_request_response" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "400"

  response_templates = {
    "application/json" = <<EOF
    {
      "message": "$input.path('$.errorMessage')"
    }
    EOF
  }

  selection_pattern = "4\\d{2}" # Match all 4xx errors
}


resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_templates = {
    "application/json" = <<EOF
    {
      "comments": "$util.parseJson($input.path('$.output')).comments"
    }
    EOF
  }

  selection_pattern = "2\\d{2}" # Match all 4xx errors
}


# Default integration response for other errors
resource "aws_api_gateway_integration_response" "default_response" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "500"

  response_templates = {
    "application/json" = <<EOF
    {
      "message": "An unexpected error occurred."
    }
    EOF
  }

  # Catch all other errors
  selection_pattern = ""
}

resource "aws_api_gateway_method_response" "method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}


resource "aws_api_gateway_deployment" "instagram_api" {
  depends_on = [aws_api_gateway_integration.step_function_integration]

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
          "states:StartSyncExecution"
        ]
        Resource = aws_sfn_state_machine.instagram_workflow.arn
      }
    ]
  })
}
