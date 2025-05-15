#!/bin/bash

# Error handling
set -e

# Default values
USERNAME="cloudwatch-dhruv-test-user"
POLICY_ARN="arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
OUTPUT_FILE="cloudwatch_credentials.txt"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username) USERNAME="$2"; shift ;;
        --output-file) OUTPUT_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "=== AWS CloudWatch Integration Setup ==="
echo "This script will:"
echo "  1. Create a new IAM user: $USERNAME"
echo "  2. Attach CloudWatchReadOnlyAccess policy"
echo "  3. Create access keys for the user"
echo "  4. Save credentials to $OUTPUT_FILE"
echo ""
echo "Ensure you have AWS CLI configured with permissions to manage IAM users."
echo ""
read -p "Continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Check AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check current AWS identity
echo "Running as:"
aws sts get-caller-identity

# Create IAM user
echo "Creating IAM user: $USERNAME..."
aws iam create-user --user-name "$USERNAME"

# Attach policy
echo "Attaching CloudWatchReadOnlyAccess policy..."
aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "$POLICY_ARN"

# Create access keys
echo "Creating access keys..."
KEY_OUTPUT=$(aws iam create-access-key --user-name "$USERNAME" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)

# Parse output
ACCESS_KEY_ID=$(echo $KEY_OUTPUT | cut -d' ' -f1)
SECRET_ACCESS_KEY=$(echo $KEY_OUTPUT | cut -d' ' -f2)

# Save credentials to file
echo "Saving credentials to $OUTPUT_FILE..."
cat > "$OUTPUT_FILE" << EOL
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
EOL

echo ""
echo "=== Setup Complete! ==="
echo "Credentials saved to $OUTPUT_FILE"
echo ""
echo "To use these credentials in your platform:"
echo "1. Access Key ID: $ACCESS_KEY_ID"
echo "2. Secret Access Key: [saved to file]"
echo ""
echo "IMPORTANT: Securely store these credentials!"
