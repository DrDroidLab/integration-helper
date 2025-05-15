#!/bin/bash

# Script to automate GCP Service Account creation, permission assignment, and key generation.

# --- Configuration ---
# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List of permissions to assign to the service account
# Add more roles here as needed, e.g., "roles/storage.objectViewer"
PERMISSIONS=(
  "roles/logging.viewer"
  "roles/monitoring.viewer"
)

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

# --- Main Script ---

# Welcome message
echo "${GREEN}--------------------------------------------------------------------${NC}"
echo "${GREEN} Google Cloud Service Account Setup Script ${NC}"
echo "${GREEN}--------------------------------------------------------------------${NC}"
echo "This script will guide you through:"
echo "1. Creating a new Service Account."
echo "2. Assigning specified permissions to it."
echo "3. Generating a JSON key for the Service Account."
echo "${BLUE}--------------------------------------------------------------------${NC}"

# Check for gcloud CLI
if ! command -v gcloud &> /dev/null; then
  error "gcloud CLI not found. Please install and configure the Google Cloud SDK."
  error "Visit: https://cloud.google.com/sdk/docs/install"
  exit 1
fi
info "gcloud CLI found."

# Attempt to get current project ID
CURRENT_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# Get Project ID
if [[ -n "$CURRENT_PROJECT_ID" ]]; then
  read -r -p "Enter your Google Cloud Project ID (default: ${CURRENT_PROJECT_ID}): " PROJECT_ID
  PROJECT_ID=${PROJECT_ID:-$CURRENT_PROJECT_ID}
else
  read -r -p "Enter your Google Cloud Project ID: " PROJECT_ID
fi

if [[ -z "$PROJECT_ID" ]]; then
  error "Project ID cannot be empty."
  exit 1
fi
info "Using Project ID: ${GREEN}$PROJECT_ID${NC}"

# Get Service Account Name
DEFAULT_SA_NAME="monitoring-viewer"
read -r -p "Enter a name for the new Service Account (default: ${DEFAULT_SA_NAME}): " SA_NAME
SA_NAME=${SA_NAME:-$DEFAULT_SA_NAME}

if [[ -z "$SA_NAME" ]]; then
  error "Service Account name cannot be empty."
  exit 1
fi

# Construct Service Account Email
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
info "Service Account will be: ${GREEN}$SA_EMAIL${NC}"

print_step "Step 1: Create Service Account"

info "Attempting to create Service Account '${GREEN}$SA_NAME${NC}'..."
gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="$SA_NAME"

if [[ $? -ne 0 ]]; then
  error "Failed to create Service Account '${RED}$SA_NAME${NC}'."
  warning "Possible reasons:"
  warning "- Service Account with this name already exists in project '$PROJECT_ID'."
  warning "- You may not have 'iam.serviceAccounts.create' permission in project '$PROJECT_ID'."
  warning "- Project ID '$PROJECT_ID' might be incorrect or you don't have access."
  warning "Please check the details and permissions, then try again."
  exit 1
fi
success "Service Account '${GREEN}$SA_NAME${NC}' created successfully: ${GREEN}$SA_EMAIL${NC}"

print_step "Step 2: Assign Permissions"

PERMISSIONS_ASSIGNED_COUNT=0
for permission in "${PERMISSIONS[@]}"; do
  info "Assigning permission '${YELLOW}$permission${NC}' to ${GREEN}$SA_EMAIL${NC}..."
  # Suppress verbose output of successful policy update, show errors only
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$permission" --condition=None --quiet 2>/dev/null
  
  # Verify the binding - this is a more reliable way to check success
  # Note: This check can sometimes be slow or have eventual consistency issues.
  # For a quicker script, one might rely on the exit code of add-iam-policy-binding, 
  # but it can sometimes be 0 even if a background process fails.
  if gcloud projects get-iam-policy "$PROJECT_ID" --format='json' | grep -q "serviceAccount:$SA_EMAIL.*role.:.\+$permission"; then
    success "Permission '${GREEN}$permission${NC}' assigned successfully to ${GREEN}$SA_EMAIL${NC}."
    PERMISSIONS_ASSIGNED_COUNT=$((PERMISSIONS_ASSIGNED_COUNT + 1))
  else
    # Attempt to re-run with verbose output if the quiet one failed verification
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:$SA_EMAIL" \
      --role="$permission" --condition=None
    
    if [[ $? -ne 0 ]]; then
      error "Failed to assign permission '${RED}$permission${NC}' to Service Account '${RED}$SA_EMAIL${NC}'."
      warning "Possible reasons:"
      warning "- You may not have 'resourcemanager.projects.setIamPolicy' permission for project '$PROJECT_ID'."
      warning "- The role '$permission' might not be valid or available for this project."
      warning "- There might be a conflicting policy or organizational restriction."
      warning "Please check the gcloud output above, GCP console IAM page, and audit logs for more details."
    else
      # If the verbose command succeeded, it means the quiet one might have had issues or the verification was too fast.
      success "Permission '${GREEN}$permission${NC}' assigned (after retry) to ${GREEN}$SA_EMAIL${NC}."
      PERMISSIONS_ASSIGNED_COUNT=$((PERMISSIONS_ASSIGNED_COUNT + 1))
    fi
  fi
done

if [[ $PERMISSIONS_ASSIGNED_COUNT -eq ${#PERMISSIONS[@]} ]]; then
  success "All ${GREEN}${PERMISSIONS_ASSIGNED_COUNT}${NC} permissions assigned successfully."
elif [[ $PERMISSIONS_ASSIGNED_COUNT -gt 0 ]]; then
  warning "${YELLOW}${PERMISSIONS_ASSIGNED_COUNT} out of ${#PERMISSIONS[@]}${NC} permissions were assigned. Please check any error messages above."
else
  error "No permissions were successfully assigned. Please review the errors."
fi

print_step "Step 3: Create JSON Key for Service Account"

KEY_FILE_BASENAME="${SA_NAME}-${PROJECT_ID}-key"
KEY_FILE="./${KEY_FILE_BASENAME}.json"

# Check if key file already exists and ask to overwrite or change name
if [[ -f "$KEY_FILE" ]]; then
  warning "Key file '${YELLOW}$KEY_FILE${NC}' already exists."
  read -r -p "Overwrite? (y/N) or enter a new name for the key file (e.g., new-key-name): " OVERWRITE_CHOICE
  OVERWRITE_CHOICE=${OVERWRITE_CHOICE:-N}
  if [[ "$OVERWRITE_CHOICE" =~ ^[Yy]$ ]]; then
    info "Overwriting existing key file: ${YELLOW}$KEY_FILE${NC}"
  elif [[ "$OVERWRITE_CHOICE" =~ ^[Nn]$ ]]; then
    error "Key creation aborted by user. Please re-run with a different Service Account name or manage existing keys."
    exit 1
  else
    # User provided a new name, ensure it ends with .json
    if [[ "$OVERWRITE_CHOICE" != *.json ]]; then
        KEY_FILE_BASENAME="$OVERWRITE_CHOICE"
        KEY_FILE="./${KEY_FILE_BASENAME}.json"
    else
        KEY_FILE="./$OVERWRITE_CHOICE"
    fi
    info "Using new key file name: ${GREEN}$KEY_FILE${NC}"
  fi
fi 

info "Creating JSON key for ${GREEN}$SA_EMAIL${NC} and saving to ${GREEN}$KEY_FILE${NC}..."

gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL" \
  --project="$PROJECT_ID"

if [[ $? -ne 0 ]]; then
  error "Failed to create JSON key for Service Account '${RED}$SA_EMAIL${NC}'."
  warning "Possible reasons:"
  warning "- You may not have 'iam.serviceAccountKeys.create' permission for '$SA_EMAIL'."
  warning "- You might have reached the maximum number of keys for this service account (limit is 10)."
  warning "- The path '$KEY_FILE' might not be writable."
  warning "Please check the details, permissions, and ensure the output directory is writable."
  exit 1
fi
success "JSON key created successfully and saved to: ${GREEN}$KEY_FILE${NC}"

echo
echo "${GREEN}====================================================================${NC}"
echo "${GREEN} GCP SETUP COMPLETE! ${NC}"
echo "${GREEN}====================================================================${NC}"
echo
success "Service Account Email: ${GREEN}$SA_EMAIL${NC}"
success "Project ID used:     ${GREEN}$PROJECT_ID${NC}"
success "JSON Key File:       ${GREEN}$(pwd)/$KEY_FILE${NC}" # Show absolute path
echo
info "Next Steps for Playbooks Integration:"
info "1. Navigate to the Google Cloud setup page in your Playbooks application."
info "2. When prompted for the ${YELLOW}Project ID${NC}, enter: ${GREEN}$PROJECT_ID${NC}"
info "3. For the ${YELLOW}Service Account JSON Key${NC}, upload or paste the content from:"
info "   ${GREEN}$(pwd)/$KEY_FILE${NC}"
info "   (Remember: The Project ID is also available inside this JSON key file)."
info "4. Test the connection and submit the configuration."
echo
warning "IMPORTANT: The JSON key file (${YELLOW}$KEY_FILE${NC}) contains sensitive credentials."
warning "Store it securely and do not commit it to version control or share it publicly."
warning "Consider using a secrets manager for long-term storage."
echo "${BLUE}--------------------------------------------------------------------${NC}"

exit 0 