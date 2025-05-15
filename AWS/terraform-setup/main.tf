# main.tf - Main configuration file

provider "aws" {
  region = var.aws_region
}

# Create IAM User
resource "aws_iam_user" "cloudwatch_user" {
  name = var.username
  path = "/"
}

# Attach CloudWatch ReadOnly Policy
resource "aws_iam_user_policy_attachment" "policy_attachment" {
  user       = aws_iam_user.cloudwatch_user.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Create Access Key
resource "aws_iam_access_key" "user_key" {
  user = aws_iam_user.cloudwatch_user.name
}
