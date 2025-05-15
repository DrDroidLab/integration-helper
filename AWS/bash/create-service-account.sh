#!/bin/bash

# Error handling
set -e

# --- Configuration ---
# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
info() {
  echo "${BLUE}[INFO] $1${NC}"
}

error() {
  echo "${RED}[ERROR] $1${NC}" >&2
}

success() {
  echo "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
  echo "${YELLOW}[WARNING] $1${NC}"
}

print_step() {
  echo "${BLUE}--------------------------------------------------------------------${NC}"
  echo "${BLUE} $1${NC}"
  echo "${BLUE}--------------------------------------------------------------------${NC}"
}

# Default values (can be overridden by user input)
DEFAULT_USERNAME="monitoring-user"
POLICY_ARN="arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"

# --- Main Script ---
echo "${GREEN}--------------------------------------------------------------------${NC}"
echo "${GREEN} AWS CloudWatch Integration Setup Script ${NC}"
echo "${GREEN}--------------------------------------------------------------------${NC}"

# Get Username
read -r -p "Enter the IAM username to create (default: ${DEFAULT_USERNAME}): " USERNAME
USERNAME=${USERNAME:-$DEFAULT_USERNAME}

echo
info "This script will:"
info "  1. Create a new IAM user: ${GREEN}$USERNAME${NC}"
info "  2. Attach CloudWatchReadOnlyAccess policy (${YELLOW}$POLICY_ARN${NC})"
info "  3. Create access keys for the user"
info "  4. Print credentials to the console${NC}"
echo
warning "Ensure you have AWS CLI configured with permissions to manage IAM users."
echo
read -p "Continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    warning "Operation cancelled by user."
    exit 0
fi
echo

# Check AWS CLI is installed and configured
print_step "Step 1: Verify AWS CLI"
if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed. Please install it first."
    error "Visit: https://aws.amazon.com/cli/"
    exit 1
fi
success "AWS CLI found."

# Check current AWS identity
info "Checking current AWS identity..."
CURRENT_IDENTITY=$(aws sts get-caller-identity --output json)
CALLER_ARN=$(echo "$CURRENT_IDENTITY" | grep '"Arn":' | cut -d'"' -f4)
CALLER_USERID=$(echo "$CURRENT_IDENTITY" | grep '"UserId":' | cut -d'"' -f4)
info "Running as IAM entity: ${GREEN}$CALLER_ARN${NC} (UserId: ${GREEN}$CALLER_USERID${NC})"
echo

print_step "Step 2: Create IAM User"
info "Attempting to create IAM user: ${GREEN}$USERNAME${NC}..."
if aws iam get-user --user-name "$USERNAME" > /dev/null 2>&1; then
  warning "IAM user ${YELLOW}$USERNAME${NC} already exists."
  read -p "Do you want to proceed with this existing user to attach policy and generate new keys? (y/n): " OVERWRITE_USER_CONFIRM
  if [[ "$OVERWRITE_USER_CONFIRM" != "y" && "$OVERWRITE_USER_CONFIRM" != "Y" ]]; then
    warning "Operation cancelled. Please choose a different username or manage the existing user manually."
    exit 0
  fi
  success "Proceeding with existing user ${GREEN}$USERNAME${NC}."
else
  aws iam create-user --user-name "$USERNAME"
  if [[ $? -ne 0 ]]; then
    error "Failed to create IAM user '${RED}$USERNAME${NC}'."
    warning "Please check permissions and AWS CLI configuration."
    exit 1
  fi
  success "IAM user '${GREEN}$USERNAME${NC}' created successfully."
fi
echo

print_step "Step 3: Attach Policy"
info "Attaching ${YELLOW}$POLICY_ARN${NC} policy to ${GREEN}$USERNAME${NC}..."
aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "$POLICY_ARN"
if [[ $? -ne 0 ]]; then
  error "Failed to attach policy '${RED}$POLICY_ARN${NC}' to user '${RED}$USERNAME${NC}'."
  exit 1
fi
success "Policy '${GREEN}$POLICY_ARN${NC}' attached successfully."
echo

print_step "Step 4: Create Access Keys"
info "Creating access keys for ${GREEN}$USERNAME${NC}..."
# Remove existing access keys if any, as a user can only have two.
# This is a common requirement before creating new ones programmatically.
EXISTING_KEYS=$(aws iam list-access-keys --user-name "$USERNAME" --query "AccessKeyMetadata[].AccessKeyId" --output text)
for KEY_ID in $EXISTING_KEYS; do
  if [[ -n "$KEY_ID" ]]; then
    warning "Found existing access key ${YELLOW}$KEY_ID${NC} for user ${GREEN}$USERNAME${NC}. It will be deleted to create new ones."
    aws iam delete-access-key --user-name "$USERNAME" --access-key-id "$KEY_ID"
    success "Deleted existing access key ${GREEN}$KEY_ID${NC}."
  fi
done

KEY_OUTPUT=$(aws iam create-access-key --user-name "$USERNAME" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
if [[ $? -ne 0 || -z "$KEY_OUTPUT" ]]; then
  error "Failed to create access keys for user '${RED}$USERNAME${NC}'."
  exit 1
fi
success "Access keys created successfully."
echo

# Parse output
ACCESS_KEY_ID=$(echo $KEY_OUTPUT | cut -d' ' -f1)
SECRET_ACCESS_KEY=$(echo $KEY_OUTPUT | cut -d' ' -f2)

if [[ -z "$ACCESS_KEY_ID" || -z "$SECRET_ACCESS_KEY" ]]; then
    error "Could not parse Access Key ID or Secret Access Key from AWS CLI output."
    exit 1
fi

echo "${GREEN}====================================================================${NC}"
echo "${GREEN} AWS SETUP COMPLETE! ${NC}"
echo "${GREEN}====================================================================${NC}"
echo
success "IAM User:            ${GREEN}$USERNAME${NC}"
success "Policy Attached:     ${GREEN}$POLICY_ARN${NC}"
success "Credentials (printed below):"
echo
info "To use these credentials in your platform:"
info "Access Key ID:     ${YELLOW}$ACCESS_KEY_ID${NC}"
info "Secret Access Key: ${YELLOW}$SECRET_ACCESS_KEY${NC}"
echo
warning "IMPORTANT: Securely store these credentials!"
warning "Do not commit it to version control or share it publicly."
echo "${BLUE}--------------------------------------------------------------------${NC}\\n"

exit 0
