## Deployment Method 1: AWS Management Console
**Step 1**: Download the CloudFormation Template

Save the CloudFormation template above as a file named cloudwatch-integration.yaml

**Step 2**: Log into the AWS Management Console

Open your browser and go to https://console.aws.amazon.com/
Sign in with your AWS account credentials
Ensure you're in the desired AWS region (visible in the top-right corner)

**Step 3**: Navigate to CloudFormation

Click on "Services" in the top navigation bar
Search for "CloudFormation" and select it from the dropdown

**Step 4**: Create a New Stack

Click the "Create stack" button
Select "With new resources (standard)"

**Step 5**: Upload the Template

In the "Specify template" section, select "Upload a template file"
Click "Choose file" and select your cloudwatch-integration.yaml file
Click "Next"

**Step 6**: Configure Stack Details

Enter a Stack name (e.g., cloudwatch-integration-stack)
Under Parameters, you can keep the default username or customize it
Click "Next"

**Step 7**: Configure Stack Options

Add any tags if desired (optional)
Configure any stack options if needed (optional)
Click "Next"

**Step 8**: Review and Create

Review all the settings and details
Check the acknowledgment box at the bottom that says AWS might create IAM resources
Click "Create stack"

**Step 9**: Wait for Stack Creation

Wait for the stack status to change to "CREATE_COMPLETE" (should take less than a minute)

**Step 10**: Access Your Credentials

Once the stack is created, go to the "Outputs" tab
You'll see the values for:

UserName: The IAM user name
AccessKeyId: The AWS access key ID
SecretAccessKey: The AWS secret access key


Copy these values or download them securely
**IMPORTANT**: This is the only time you can view the SecretAccessKey. It won't be retrievable later.

## Deployment Method 2: AWS CLI
PREREQUISITES:

Before proceeding, ensure your AWS CLI environment is properly configured. There are a couple of ways to do this:

1.  **Using `aws configure` (Recommended for this guide):**
    *   Run `aws configure` and provide your AWS Access Key ID, AWS Secret Access Key, and optionally, a Default region name.
    *   If you specify a Default region name during `aws configure`, you will **not** need to add the `--region YOUR_REGION` parameter to the `aws cloudformation` commands in the steps below.
    *   If you do **not** specify a Default region name, you **must** append `--region YOUR_REGION` (replacing `YOUR_REGION` with your target region, e.g., `us-east-1`) to all `aws cloudformation` commands.
    *   **For the purpose of this guide, we will assume `aws configure` has been completed.**

2.  **Using Environment Variables:**
    *   You can set the following environment variables in your terminal session:
        *   `AWS_ACCESS_KEY_ID`
        *   `AWS_SECRET_ACCESS_KEY`
        *   `AWS_SESSION_TOKEN` (if using temporary credentials)
        *   `AWS_DEFAULT_REGION` (optional, but recommended if you want to avoid specifying `--region` in every command)
    *   If `AWS_DEFAULT_REGION` is set, you do not need to add `--region` to your commands.
    *   If `AWS_DEFAULT_REGION` is **not** set, you **must** append `--region YOUR_REGION` to all `aws cloudformation` commands.

**Step 1**: Save the Template Locally

Save the CloudFormation template to a file named cloudwatch-integration.yaml

**Step 2**: Validate the Template (Optional but Recommended)

Run:
aws cloudformation validate-template --template-body file://cloudwatch-integration.yaml

If the template is valid, you'll see the parameters defined in the template

**Step 3**: Create the CloudFormation Stack

Run:
aws cloudformation create-stack \
  --stack-name cloudwatch-integration-stack \
  --template-body file://cloudwatch-integration.yaml \
  --capabilities CAPABILITY_NAMED_IAM

Note: CAPABILITY_NAMED_IAM is required because we're creating IAM resources with specific names

**Step 4**: Check Stack Creation Status

Run:
```
aws cloudformation describe-stacks \
  --stack-name cloudwatch-integration-stack
```

Wait until the "StackStatus" shows "CREATE_COMPLETE"

**Step 5**: Retrieve Your Credentials

Run:
```
aws cloudformation describe-stacks \
  --stack-name cloudwatch-integration-stack \
  --query "Stacks[0].Outputs"
```

This will display all outputs including the access key and secret
For a more focused result, you can use:

```
aws cloudformation describe-stacks \
  --stack-name cloudwatch-integration-stack \
  --query "Stacks[0].Outputs[?OutputKey=='AccessKeyId' || OutputKey=='SecretAccessKey' || OutputKey=='UserName'].{Key:OutputKey,Value:OutputValue}"
```

**Step 6**: Store Credentials Securely

Save these credentials in a secure location
IMPORTANT: The SecretAccessKey will only be available at this point and cannot be retrieved later

