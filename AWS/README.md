# AWS IAM User Setup for Playbooks Integration

This document provides three methods to create an AWS IAM (Identity and Access Management) User with the necessary permissions (CloudWatchReadOnlyAccess) and generate access keys. This setup is typically required for integrating external applications like Playbooks with AWS CloudWatch.

## Prerequisites (Common for all methods)

1.  **AWS CLI**: Ensure the AWS Command Line Interface is installed and configured on your system.
    *   Installation: [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
    *   Configuration: Run `aws configure` and provide your AWS Access Key ID, Secret AccessKey, and default region. You can get these from an existing IAM user with sufficient permissions or your root account (not recommended for daily use).
        ```bash
        aws configure
        ```
2.  **Sufficient IAM Permissions**: The AWS identity (user or role) you use to run these methods must have permissions to:
    *   Create IAM users (`iam:CreateUser`)
    *   Attach policies to users (`iam:AttachUserPolicy`)
    *   Create access keys for users (`iam:CreateAccessKey`)
    *   (For CloudFormation method): Create CloudFormation stacks (`cloudformation:CreateStack`, `cloudformation:DescribeStacks`) and manage IAM resources via CloudFormation.
    *   A policy similar to `IAMFullAccess` or a custom policy granting these specific actions is typically required.

## Method 1: Using the Bash Script (`bash-setup/create-service-account.sh`)

This method uses a shell script to interactively guide you through creating an IAM user, attaching the `CloudWatchReadOnlyAccess` policy, and generating access keys.

### Steps:

1.  **Navigate to the script directory**:
    ```bash
    cd AWS/bash-setup
    ```

2.  **Make the script executable** (if not already):
    ```bash
    chmod +x create-service-account.sh
    ```

3.  **Run the script**:
    ```bash
    ./create-service-account.sh
    ```
    You can optionally specify a username and output file:
    ```bash
    ./create-service-account.sh --username my-playbooks-user --output-file my-creds.txt
    ```
    The default username is `cloudwatch-dhruv-test-user` and the default output file is `cloudwatch_credentials.txt`.

4.  **Follow the prompts**:
    *   The script will display the actions it will perform and ask for confirmation.

### Outputs:

*   The script will create an IAM user with the `CloudWatchReadOnlyAccess` policy.
*   It will generate an Access Key ID and a Secret Access Key for the user.
*   These credentials will be saved to the specified output file (e.g., `cloudwatch_credentials.txt`) in the `bash-setup` directory.
*   The Access Key ID will also be printed to the console.

## Method 2: Using Terraform (`terraform-setup/`)

This method uses Infrastructure as Code (IaC) with Terraform to provision and manage the IAM user and associated resources.

### Prerequisites:

*   **Terraform CLI**: Install Terraform from [developer.hashicorp.com](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

### Directory Structure (`AWS/terraform-setup/`):

*   `main.tf`: Defines the AWS resources (IAM user, policy attachment, access key).
*   `variables.tf`: Defines input variables (e.g., username).
*   `outputs.tf`: Specifies output values (access key ID, secret access key).
*   `terraform.tfvars`: (Optional) Use this file to provide variable values.

### Steps:

1.  **Navigate to the Terraform directory**:
    ```bash
    cd AWS/terraform-setup
    ```

2.  **Initialize Terraform**:
    This downloads the AWS provider plugin.
    ```bash
    terraform init
    ```

3.  **(Optional) Create `terraform.tfvars`**:
    You can create a `terraform.tfvars` file in this directory to customize variables, for example:
    ```hcl
    aws_region    = "us-east-1"
    iam_user_name = "playbooks-tf-user"
    ```

4.  **Plan the deployment**:
    Review the resources Terraform will create.
    ```bash
    terraform plan
    ```

5.  **Apply the configuration**:
    This creates the IAM user and access key. Confirm by typing `yes` when prompted.
    ```bash
    terraform apply
    ```

### Outputs:

After a successful `terraform apply`, Terraform will display the outputs:
*   `access_key_id`: The AWS Access Key ID.
*   `secret_access_key`: The AWS Secret Access Key. **This is sensitive.**

You can retrieve these outputs again using:
```bash
terraform output access_key_id
terraform output -raw secret_access_key
```

### Cleanup:

To remove the resources created by Terraform:
```bash
terraform destroy
```
Confirm by typing `yes` when prompted.

## Method 3: Using AWS CloudFormation (`cloudformation-setup/`)

This method uses an AWS CloudFormation template (`cloudwatch-integration.yaml`) to define and deploy the necessary AWS resources.

### Template:

*   `AWS/cloudformation-setup/cloudwatch-integration.yaml`: The CloudFormation template that creates an IAM user and an access key, and attaches the `CloudWatchReadOnlyAccess` policy.

You can deploy this template using either the AWS Management Console or the AWS CLI.

### Option A: Deployment via AWS Management Console

1.  **Log into the AWS Management Console**: Go to [console.aws.amazon.com](https://console.aws.amazon.com/) and ensure you are in your desired AWS region.
2.  **Navigate to CloudFormation**: Search for "CloudFormation" in the services menu.
3.  **Create Stack**: Click "Create stack" and select "With new resources (standard)".
4.  **Specify Template**:
    *   Choose "Upload a template file".
    *   Click "Choose file" and select `AWS/cloudformation-setup/cloudwatch-integration.yaml`.
    *   Click "Next".
5.  **Specify Stack Details**:
    *   Enter a **Stack name** (e.g., `playbooks-cloudwatch-stack`).
    *   You can customize the `IAMUserNameParameter` if needed (default is `CloudWatchIntegrationUser`).
    *   Click "Next".
6.  **Configure Stack Options**: Add tags or configure other options if desired. Click "Next".
7.  **Review and Create**:
    *   Review the stack details.
    *   **Important**: Check the box acknowledging that "AWS CloudFormation might create IAM resources with custom names."
    *   Click "Create stack".
8.  **Wait for Completion**: The stack status should change to `CREATE_COMPLETE`.
9.  **Access Outputs**: Go to the "Outputs" tab of your created stack. You will find:
    *   `UserName`: The IAM user name.
    *   `AccessKeyId`: The AWS Access Key ID.
    *   `SecretAccessKey`: The AWS Secret Access Key. **Copy this immediately as it won't be retrievable later through the console.**

### Option B: Deployment via AWS CLI

1.  **Navigate to the CloudFormation directory**:
    ```bash
    cd AWS/cloudformation-setup
    ```
2.  **(Optional) Validate the template**:
    ```bash
    aws cloudformation validate-template --template-body file://cloudwatch-integration.yaml
    ```
3.  **Create the stack**:
    Replace `your-stack-name` with a name for your stack (e.g., `playbooks-cloudwatch-stack`).
    If your AWS CLI is not configured with a default region, add `--region YOUR_REGION`.
    ```bash
    aws cloudformation create-stack \
      --stack-name your-stack-name \
      --template-body file://cloudwatch-integration.yaml \
      --capabilities CAPABILITY_NAMED_IAM 
    # You can also override parameters:
    # --parameters ParameterKey=IAMUserNameParameter,ParameterValue=my-cf-user
    ```
    The `CAPABILITY_NAMED_IAM` is required because the template creates IAM resources with specific names.

4.  **Check stack creation status**:
    ```bash
    aws cloudformation describe-stacks --stack-name your-stack-name --query "Stacks[0].StackStatus"
    ```
    Wait for the status to become `CREATE_COMPLETE`.

5.  **Retrieve outputs**:
    ```bash
    aws cloudformation describe-stacks --stack-name your-stack-name --query "Stacks[0].Outputs"
    ```
    This will display the `UserName`, `AccessKeyId`, and `SecretAccessKey`.

## Using the Credentials with Playbooks

Once you have the **Access Key ID** and **Secret Access Key** (and optionally the IAM User Name/ARN) from any of the methods above:

1.  Navigate to the AWS CloudWatch integration setup page in your Playbooks application.
2.  Enter the Access Key ID.
3.  Enter the Secret Access Key.
4.  Provide any other requested information (like AWS Region, if applicable).
5.  Test the connection and submit the configuration.

## Security Best Practices

*   **Securely Store Credentials**: The generated Access Key ID and Secret Access Key are sensitive. Treat them like passwords.
    *   Store them in a secure location (e.g., a password manager, AWS Secrets Manager, HashiCorp Vault).
    *   Do not embed them directly in code or commit them to version control.
*   **Principle of Least Privilege**: The provided methods aim to grant `CloudWatchReadOnlyAccess`. If your integration requires different permissions, adjust the policies accordingly, always granting only the necessary permissions.
*   **Key Rotation**: Regularly rotate your access keys as a security best practice.
*   **Monitor IAM Activity**: Use AWS CloudTrail and IAM Access Advisor to monitor the activity of the IAM user and its keys.
*   **Terraform State**: If using Terraform, manage your `terraform.tfstate` file securely, especially if working in a team. Consider using remote state backends like S3 with encryption and versioning. Do not commit the local state file to version control if it contains sensitive outputs.

This consolidated guide should help you choose the method that best fits your workflow for setting up AWS IAM users for Playbooks integration. 