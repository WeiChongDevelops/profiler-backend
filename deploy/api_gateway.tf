# API Gateway REST API
resource "aws_api_gateway_rest_api" "instagram_api" {
  name = "instagram-api"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  parent_id   = aws_api_gateway_rest_api.instagram_api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.instagram_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id             = aws_api_gateway_rest_api.instagram_api.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
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

# Integration responses
resource "aws_api_gateway_integration_response" "bad_request_response" {
  rest_api_id       = aws_api_gateway_rest_api.instagram_api.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy.http_method
  status_code       = "400"
  selection_pattern = "4\\d{2}" # Match all 4xx errors

  response_templates = {
    "application/json" = <<EOF
{
  "message": "$input.path('$.errorMessage')"
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id       = aws_api_gateway_rest_api.instagram_api.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy.http_method
  status_code       = "200"
  selection_pattern = "2\\d{2}" # Match all 2xx successes

  response_templates = {
    "application/json" = <<EOF
{
  "comments": "$util.parseJson($input.path('$.output')).comments"
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "default_response" {
  rest_api_id       = aws_api_gateway_rest_api.instagram_api.id
  resource_id       = aws_api_gateway_resource.proxy.id
  http_method       = aws_api_gateway_method.proxy.http_method
  status_code       = "500"
  selection_pattern = "" # Catch all other errors

  response_templates = {
    "application/json" = <<EOF
{
  "message": "An unexpected error occurred."
}
EOF
  }
}

# Method responses
resource "aws_api_gateway_method_response" "method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "instagram_api" {
  depends_on = [aws_api_gateway_integration.step_function_integration]

  rest_api_id = aws_api_gateway_rest_api.instagram_api.id
  stage_name  = "prod"
}