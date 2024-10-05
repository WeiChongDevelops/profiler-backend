variable "aws_region" {
  default = "ap-southeast-2"
}

variable "hiker_api_key" {
  description = "API key for Hiker API"
  type        = string
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "API key for Anthropic API"
  type        = string
  sensitive   = true
}

variable "lamatok_api_key" {
  description = "API key for Lamatok API"
  type        = string
  sensitive   = true
}