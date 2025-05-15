#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define the list of roles to be assigned
ROLES_TO_ASSIGN=(
    "Monitoring Reader"
    "Log Analytics Reader"
)

echo "${GREEN}===== Azure Log Analytics Setup Script =====${NC}"
echo "This script will:"
echo "1. Verify Azure CLI is installed and you're logged in"
echo "2. Create an Entra app registration"
echo "3. Add required API permissions"
echo "4. Create a service principal with the following roles:"
for role in "${ROLES_TO_ASSIGN[@]}"; do
    echo "   - $role"
done
echo "5. Generate and retrieve all required keys/IDs"
echo

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display error and exit
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    echo -e "${YELLOW}Suggestion: $2${NC}"
    exit 1
}

# Check if Azure CLI is installed
if ! command_exists az; then
    error_exit "Azure CLI is not installed." "Please install Azure CLI first. Visit https://docs.microsoft.com/cli/azure/install-azure-cli for instructions."
fi

# Check if user is logged in to Azure CLI
echo "Checking if you're logged in to Azure..."
account_info=$(az account show 2>/dev/null)
if [ $? -ne 0 ]; then
    error_exit "You're not logged in to Azure CLI." "Please run 'az login' first and try again."
fi

# Get subscription ID
echo "Retrieving subscription information..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "${GREEN}Using subscription ID: ${SUBSCRIPTION_ID}${NC}"

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "${GREEN}Using tenant ID: ${TENANT_ID}${NC}"

# Prompt for app name
read -p "Enter a name for your Azure Entra app registration (default: LogAnalyticsApp): " APP_NAME
APP_NAME=${APP_NAME:-LogAnalyticsApp}

echo "${YELLOW}Creating Azure Entra app registration and service principal '${APP_NAME}'...${NC}"

# Create the app registration with service principal using create-for-rbac
echo "Creating app registration and service principal..."
SP_CREATE=$(az ad sp create-for-rbac --name "$APP_NAME" --skip-assignment 2>&1)
if [ $? -ne 0 ]; then
    error_exit "Failed to create app registration and service principal. Error: $SP_CREATE" "Ensure you have permissions to create applications and service principals in the directory."
fi

# Extract the required IDs from the service principal creation
CLIENT_ID=$(echo "$SP_CREATE" | grep -o '"appId": "[^"]*' | cut -d'"' -f4)
if [ -z "$CLIENT_ID" ]; then
    CLIENT_ID=$(echo "$SP_CREATE" | grep -o '"appId":[^,]*' | cut -d'"' -f4)
fi

# Get the client secret from the output
CLIENT_SECRET=$(echo "$SP_CREATE" | grep -o '"password": "[^"]*' | cut -d'"' -f4)
if [ -z "$CLIENT_SECRET" ]; then
    CLIENT_SECRET=$(echo "$SP_CREATE" | grep -o '"password":[^,]*' | cut -d'"' -f4)
fi

echo "${GREEN}App registration and service principal created with client ID: ${CLIENT_ID}${NC}"

# Add API permissions
echo "Adding required API permissions..."

# Azure Service Management API - user_impersonation (Delegated)
echo "Adding Azure Service Management API permission..."
az ad app permission add --id "$CLIENT_ID" \
    --api 797f4846-ba00-4fd7-ba43-dac1f8f63013 \
    --api-permissions 41094075-9dad-400e-a0bd-54e686782033=Scope

# Log Analytics API - Data.Read (Application)
echo "Adding Log Analytics API permission..."
az ad app permission add --id "$CLIENT_ID" \
    --api ca7f3f0b-7d91-482c-8e09-c5d840d0eac5 \
    --api-permissions 73c7b4b0-5cd3-4efd-b947-62fe4185be46=Role

echo "${GREEN}API permissions added.${NC}"

# Add Microsoft Graph User.Read (Delegated) permission
echo "Adding Microsoft Graph User.Read permission..."
az ad app permission add --id "$CLIENT_ID" \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

# Assign roles to service principal
echo "Assigning roles to service principal..."
SUCCESSFUL_ROLES=()
FAILED_ROLES=()

for role in "${ROLES_TO_ASSIGN[@]}"; do
    echo "Assigning role: $role"
    ROLE_ASSIGNMENT=$(az role assignment create --assignee "$CLIENT_ID" \
        --role "$role" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" 2>&1)

    if [ $? -ne 0 ]; then
        echo "${RED}Warning: Could not assign role '$role'. Error: $ROLE_ASSIGNMENT${NC}"
        FAILED_ROLES+=("$role")
    else
        echo "${GREEN}Role '$role' assigned successfully.${NC}"
        SUCCESSFUL_ROLES+=("$role")
    fi
done

# Output summary
echo
echo "${GREEN}========== SETUP COMPLETE ========${NC}"
echo

# Display roles summary
if [ ${#SUCCESSFUL_ROLES[@]} -gt 0 ]; then
    echo "${GREEN}Successfully assigned roles:${NC}"
    for role in "${SUCCESSFUL_ROLES[@]}"; do
        echo " - ${GREEN}$role${NC}"
    done
fi

if [ ${#FAILED_ROLES[@]} -gt 0 ]; then
    echo "${RED}Failed to assign roles:${NC}"
    for role in "${FAILED_ROLES[@]}"; do
        echo " - ${RED}$role${NC}"
    done
    echo "${YELLOW}You may need to manually assign these roles in the Azure portal or verify your permissions.${NC}"
fi

echo
echo "${YELLOW}Here are your configuration values:${NC}"
echo "Subscription ID: ${GREEN}$SUBSCRIPTION_ID${NC}"
echo "Tenant ID:       ${GREEN}$TENANT_ID${NC}"
echo "Client ID:       ${GREEN}$CLIENT_ID${NC}"
echo "Client Secret:   ${GREEN}$CLIENT_SECRET${NC}"
echo
echo "${YELLOW}IMPORTANT: Save these values securely. The Client Secret cannot be retrieved later.${NC}"
echo
echo "${GREEN}Done!${NC}"