# Configure the AWS provider
provider "aws" {
  region = "ap-southeast-2"  # Replace with your desired AWS region
}

# Define Lambda functions
locals {
  lambda_functions = [
    "get_instagram_user_id",
    "get_post_comments",
    "get_user_post_ids"
  ]
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

  filename      = "../lambda_functions/${local.lambda_functions[count.index]}/handler.py"
  function_name = local.lambda_functions[count.index]
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  source_code_hash = filebase64sha256("../lambda_functions/${local.lambda_functions[count.index]}/handler.py")
}