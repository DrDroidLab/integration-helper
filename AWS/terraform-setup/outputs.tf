# outputs.tf - Output definitions

output "access_key_id" {
  value       = aws_iam_access_key.user_key.id
  description = "Access Key ID for CloudWatch integration"
}

output "secret_access_key" {
  value       = aws_iam_access_key.user_key.secret
  description = "Secret Access Key for CloudWatch integration"
  sensitive   = true
}

output "instructions" {
  value = <<-EOT
    ======= AWS CloudWatch Integration Credentials =======
    
    Your credentials for the CloudWatch integration are:
    
    User: ${aws_iam_user.cloudwatch_user.name}
    Access Key ID: ${aws_iam_access_key.user_key.id}
    Secret Access Key: [Use 'terraform output -raw secret_access_key' to get the value]
    
    Use these credentials in your integration platform to connect to CloudWatch.
    IMPORTANT: Store these credentials securely!
  EOT
}
