#!/bin/bash
# This script manages the CloudFormation stack for Terraform backend resources.

# Function to get user input
get_input() {
    local prompt="$1"
    local variable="$2"
    local default="$3"

    if [[ -n $default ]]; then
        read -p "$prompt [$default]: " $variable
        eval $variable="\${$variable:-$default}"
    else
        read -p "$prompt: " $variable
    fi
}

# Set region
aws configure set region us-east-2
aws_region=$(aws configure get region)

# Get account id
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Get user input
get_input "Enter your app name" app_name
get_input "Enter the repo name (e.g. myorg/myrepo)" github_repo
get_input "Enter a unique identifier for the S3 bucket" unique_bucket_id

# Set stack name
stack_name="${app_name}-tf-backend"

# Display action options
echo ""
echo "Choose an action:"
echo "C: Create new stack"
echo "U: Update existing stack"
echo "D: Delete existing stack"
echo ""

# Get user action
get_input "Enter your choice (C/U/D)" action

# Function to wait for stack operation to complete
wait_for_stack() {
    local operation=$1
    echo "Waiting for stack $operation to complete..."
    aws cloudformation wait stack-$operation-complete --stack-name $stack_name
    if [ $? -eq 0 ]; then
        echo "Stack $operation completed successfully."
    else
        echo "Stack $operation failed. Check the AWS CloudFormation console for more details."
        exit 1
    fi
}

# Process the action
case $action in
    [Cc])
        echo "Creating new CloudFormation stack..."
        aws cloudformation create-stack \
            --stack-name $stack_name \
            --template-body file://cloudformation-template.yaml \
            --parameters ParameterKey=AppName,ParameterValue=$app_name \
                         ParameterKey=GithubRepo,ParameterValue=$github_repo \
                         ParameterKey=UniqueBucketId,ParameterValue=$unique_bucket_id \
            --capabilities CAPABILITY_NAMED_IAM
            --output json
        wait_for_stack "create"

        # Get the Terraform Role ARN from the stack outputs
        tf_role_arn=$(aws cloudformation describe-stacks --stack-name $stack_name --query "Stacks[0].Outputs[?OutputKey=='TerraformRoleArn'].OutputValue" --output text)
        echo $tf_role_arn > $app_name-tf-role-arn.txt
        echo "Terraform Role ARN saved to $app_name-tf-role-arn.txt"
        ;;
    [Uu])
        echo "Updating existing CloudFormation stack..."
        aws cloudformation update-stack \
            --stack-name $stack_name \
            --template-body file://cloudformation-template.yaml \
            --parameters ParameterKey=AppName,ParameterValue=$app_name \
                         ParameterKey=GithubRepo,ParameterValue=$github_repo \
                         ParameterKey=UniqueBucketId,ParameterValue=$unique_bucket_id \
            --capabilities CAPABILITY_NAMED_IAM
        wait_for_stack "update"
        ;;
    [Dd])
        echo "Deleting CloudFormation stack..."
        aws cloudformation delete-stack --stack-name $stack_name
        wait_for_stack "delete"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Operation completed."
