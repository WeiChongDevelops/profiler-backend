# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "instagram_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach policy to allow the Lambda function to interact with Bedrock
resource "aws_iam_policy" "lambda_bedrock_policy" {
  name = "lambda_bedrock_access_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:ListModels",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the Bedrock policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_bedrock_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
}

# Attach basic Lambda execution policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "step_functions_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

# IAM Policy for Step Functions to invoke Lambda
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "step_functions_policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.instagram_functions[*].arn
    }]
  })
}

# IAM Role for API Gateway to invoke Step Functions
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "api_gateway_policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartSyncExecution"]
      Resource = aws_sfn_state_machine.instagram_workflow.arn
    }]
  })
}