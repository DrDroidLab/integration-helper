# variables.tf - Variable definitions

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Change this to your preferred region
}

variable "username" {
  description = "Name of the IAM user for CloudWatch access"
  type        = string
  default     = "cloudwatch-integration-user"
}
