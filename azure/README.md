# Azure Log Analytics Integration Setup

This repository contains two approaches to set up an Azure Entra (formerly Azure AD) app registration with the necessary permissions for Log Analytics integration:

1. Using a Bash script
2. Using Terraform

Both approaches will:
1. Create an Azure Entra app registration
2. Add required API permissions:
   - Azure Service Management API - user_impersonation (Delegated)
   - Log Analytics API - Data.Read (Application)
   - Microsoft Graph - User.Read (Delegated)
3. Create a service principal with the following roles:
   - Monitoring Reader
   - Log Analytics Reader
4. Generate and provide the required configuration values (Subscription ID, Tenant ID, Client ID, Client Secret)

## Prerequisites

- Azure CLI installed and authenticated
- For Terraform approach: Terraform CLI installed (version 1.0.0+)

## Approach 1: Using Bash Script

### Setup Instructions

1. **Log in to Azure CLI:**

```bash
az login
```

2. **Run the setup script:**

```bash
./bash-setup/setup_azure_log_analytics.sh
```

3. **Follow the prompts** to create the app registration and service principal.

4. **Save the output values** displayed at the end of the script:
   - Subscription ID
   - Tenant ID
   - Client ID
   - Client Secret

## Approach 2: Using Terraform

### Setup Instructions

1. **Log in to Azure CLI:**

```bash
az login
```

2. **Navigate to the terraform directory:**

```bash
cd terraform
```

3. **Initialize Terraform:**

```bash
terraform init
```

4. **Customize the application name (optional):**

You can set a custom application name (default is "LogAnalyticsApp"):

```bash
terraform apply -var="app_name=MyCustomAppName"
```

Or create a `terraform.tfvars` file:
```hcl
app_name = "MyCustomAppName"
```

5. **Apply the Terraform configuration:**

```bash
terraform apply
```

6. **Retrieve the configuration values:**

After the Terraform apply completes successfully, the output will include:
- Subscription ID
- Tenant ID
- Client ID

To retrieve the sensitive client secret value:

```bash
terraform output -raw client_secret
```

## Important Notes

- **Client Secret**: This value is generated during creation and cannot be retrieved later. Store it securely.
- **API Permissions**: When using Terraform, admin consent for the API permissions may still need to be granted through the Azure portal.
- **Role Assignments**: Both approaches attempt to assign the necessary roles, but this may fail if your account does not have sufficient privileges. In such cases, you'll need to assign roles manually.
- **Service Principal Replication**: The Terraform configuration uses `skip_service_principal_aad_check = true` for role assignments to avoid failures due to Azure AD replication lag.

## Troubleshooting

### Common Issues with Bash Script:
- If the script fails to create the app registration, verify you have the necessary Azure AD permissions.
- If role assignments fail, check your subscription-level permissions and assign roles manually if needed.

### Common Issues with Terraform:
- If you get authentication errors, ensure you're logged in with `az login`.
- If permission errors occur, verify your Azure AD and subscription-level permissions. 
- If role assignments fail with "PrincipalNotFound" errors, this may be due to Azure AD replication delays. The configuration uses `skip_service_principal_aad_check = true` to help with this, but you might need to run `terraform apply` again after a few minutes if issues persist. 

### Required Permissions
- Global Secure Access Administrator
- Global Admin / Application Admin / Cloud Application Admin