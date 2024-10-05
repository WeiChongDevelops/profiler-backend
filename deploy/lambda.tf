# Create a Lambda Layer
resource "aws_lambda_layer_version" "common_layer" {
  filename           = "${path.module}/../lambda_layers/common_layer/layer.zip"
  layer_name         = "common_layer"
  compatible_runtimes = ["python3.11"]

  source_code_hash = filebase64sha256("${path.module}/../lambda_layers/common_layer/layer.zip")
}

# Create Lambda functions
resource "aws_lambda_function" "instagram_functions" {
  count = length(local.lambda_functions)

  filename      = "../lambda_functions/${local.lambda_functions[count.index]}/function.zip"
  function_name = local.lambda_functions[count.index]
  role          = aws_iam_role.lambda_role.arn
  timeout       = 140
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  environment {
    variables = {
      HIKER_API_KEY     = var.hiker_api_key
      ANTHROPIC_API_KEY = var.anthropic_api_key
    }
  }

  source_code_hash = filebase64sha256("../lambda_functions/${local.lambda_functions[count.index]}/handler.py")

  layers = [aws_lambda_layer_version.common_layer.arn]
}