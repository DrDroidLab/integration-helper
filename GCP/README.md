# GCP Service Account Setup for Playbooks Integration

This document outlines two methods to create a Google Cloud Platform (GCP) Service Account, assign it necessary permissions, and generate a JSON key. This setup is typically required for integrating external applications like Playbooks with GCP services.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Google Cloud SDK (gcloud CLI)**: Required for both methods. It's used for authentication and interacting with your GCP project.
    *   Installation: [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs/install)
    *   Initialize and authenticate: `gcloud init` and `gcloud auth application-default login`.
2.  **Terraform CLI** (Only for Method 2): Required if you choose to use the Terraform method.
    *   Installation: [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

Ensure you have a GCP Project created and you have sufficient permissions within that project to create service accounts and assign IAM roles (e.g., `roles/iam.serviceAccountAdmin`, `roles/resourcemanager.projectIamAdmin`).

## Method 1: Using the Bash Script (`bash/gcp_setup.sh`)

This method uses a shell script to interactively guide you through the setup process.

### Steps:

1.  **Navigate to the script directory**:
    ```bash
    cd GCP/bash
    ```

2.  **Make the script executable** (if not already):
    ```bash
    chmod +x gcp_setup.sh
    ```

3.  **Run the script**:
    ```bash
    ./gcp_setup.sh
    ```

4.  **Follow the prompts**:
    *   The script will ask for your **GCP Project ID**.
    *   It will ask for a **name for the new Service Account** (default: `monitoring-viewer`).
    *   It will then create the service account, assign predefined permissions (currently `roles/logging.viewer` and `roles/monitoring.viewer` as defined in the script), and generate a JSON key file.

### Outputs:

The script will display:
*   The Service Account email.
*   The Project ID used.
*   The absolute path to the generated JSON key file (e.g., `./<sa-name>-<project-id>-key.json`).

## Method 2: Using Terraform (`terraform/`)

This method uses Infrastructure as Code (IaC) principles with Terraform to provision and manage the GCP resources declaratively.

### Directory Structure:

*   `GCP/terraform/providers.tf`: Configures the Google Cloud provider.
*   `GCP/terraform/variables.tf`: Defines input variables. You will need to provide `project_id`. You can also customize `sa_name` (default: `playbooks-logs-viewer`) and `roles` (default: `["roles/logging.viewer", "roles/monitoring.viewer"]`).
*   `GCP/terraform/main.tf`: Defines the GCP resources (service account, IAM bindings, service account key).
*   `GCP/terraform/outputs.tf`: Specifies the output values after successful execution.

### Steps:

1.  **Navigate to the Terraform directory**:
    ```bash
    cd GCP/terraform
    ```

2.  **Initialize Terraform**:
    This downloads the necessary provider plugins.
    ```bash
    terraform init
    ```

3.  **Create a `terraform.tfvars` file** (recommended) to specify your project ID:
    Create a file named `terraform.tfvars` in the `GCP/terraform` directory with the following content:
    ```hcl
    project_id = "your-gcp-project-id" 
    // You can also override other variables here, for example:
    // sa_name = "my-custom-sa"
    // roles   = ["roles/logging.viewer", "roles/storage.objectViewer"]
    ```
    Replace `your-gcp-project-id` with your actual GCP Project ID.
    Alternatively, you can pass variables via the command line (e.g., `-var="project_id=your-gcp-project-id"`).

4.  **Plan the deployment**:
    This command shows you what resources Terraform will create, modify, or destroy.
    ```bash
    terraform plan
    ```

5.  **Apply the configuration**:
    This command creates the resources in your GCP project. Confirm by typing `yes` when prompted.
    ```bash
    terraform apply
    ```

### Outputs:

After a successful `terraform apply`, Terraform will display the outputs defined in `outputs.tf`:
*   `service_account_email`: The email of the created service account.
*   `service_account_key_json`: The base64 encoded JSON private key. **This is sensitive information.**
*   `project_id_used`: The project ID where resources were deployed.

To get the JSON key content directly (and decode it from base64), you can use:
```bash
terraform output -raw service_account_key_json > service-account-key.json
```
This will save the key to a file named `service-account-key.json` in the current directory (`GCP/terraform`).

## Using the Credentials with Playbooks

Once you have the Service Account JSON key and your Project ID (which is also inside the JSON key file):

1.  Navigate to the **Google Cloud setup page** in your Playbooks application.
2.  When prompted for the **Project ID**, enter the GCP Project ID you used.
3.  For the **Service Account JSON Key**, upload the generated JSON file or paste its content.
4.  Test the connection and submit the configuration.

## Security Reminder

**The generated JSON key file contains sensitive credentials that grant access to your GCP resources.**

*   **Store it securely**: Treat this file like a password.
*   **Do not commit it to version control** (e.g., Git).
*   **Limit its distribution**: Only share it with individuals or systems that absolutely require it.
*   **Consider using a secrets manager** (like Google Secret Manager, HashiCorp Vault, etc.) for long-term storage and access control, especially in production environments.
*   **Regularly rotate keys** as per your security policy.

By default, the Terraform output for `service_account_key_json` is marked as sensitive, so it won't be displayed directly in the console log after `apply` unless explicitly requested with `terraform output service_account_key_json`. 

## Required Permissions
- Service Account Key Admin
- IAM Security Admin