# Output the API Gateway Invoke URL
output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.instagram_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.instagram_api.stage_name}"
}