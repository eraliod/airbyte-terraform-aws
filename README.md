# AWS Terraform Documentation
The code in this repository establishes an airbyte server, all of its necessary infrastructure, and a few connections for data extraction and loading.

It uses terraform to create all infrastructure as code. Once the pre-requisites have been taken care of, any code updates to the main branch will trigger terraform to plan and apply changes.

Note that this is a proof of concept (POC) and the code is in minimum viable product (MVP) state.

## Pre-requisites

Before the GitHub Actions workflow can run Terraform to create the AWS resources, you need to perform the following steps manually:
#### AWS AIM user for Terraform
Terraform will need to have privilege to create aws resources and interact with the s3 bucket hosting the state files

1. Create a new user `airbyte-poc-user` in aws iam
2. Attach standard policies to the user
   - AmazonDynamoDBFullAccess
   - AmazonEC2FullAccess
   - AmazonRDSFullAccess
   - AmazonS3FullAccess
   - AmazonSSMFullAccess
   - IAMFullAccess
3. Create an Access Key (access_key_id & secret_access_key)


   > - *This needs to be updated to follow devops best practices before production. For example, the use of IAM Roles.*
   > - *Considered narrowing permissions but terraform needs a lot, so for this POC I went with full access to the resource types needed (EC2, S3, SSM, AIM, RDS, Dynamo)*

#### GitHub Secrets
Configure the following secrets in your GitHub repository. *Can also configure these locally if intending to run terraform commands from local development machine*:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.

#### SSM Parameter Store Secrets
   For the aws infrastructure
   - `/airbyte/poc/postgres_db_user_password`: The RDS Postgres db password
   - `/airbyte/poc/server_admin_password`: The Airbyte server basic authentication password
   - `/airbyte/poc/server_admin_username`: The Airbyte server basic authentication username

   For the airbyte connections
   - `/airbyte/poc/bingads_client_id`: Bing Ads Client ID
   - `/airbyte/poc/bingads_developer_token`: Bing Ads Developer Token
   - `/airbyte/poc/bingads_client_secret`: Bing Ads Client Secret
   - `/airbyte/poc/bingads_refresh_token`: Bing Ads API Refresh Token

#### Terraform Backend Bucket
This bucket will be used to store the Terraform state file.

Create an S3 bucket named `airbyte-poc-tf-state` in the `us-east-2` region for Terraform backend. 

#### DynamoDB Table for State Lock
This table will be used for state locking to prevent concurrent runs of Terraform.

Create a DynamoDB table named `airbyte_poc_tf_state_lock` with a primary key named `LockID` of type String.

## Optional Configuration
#### Security Groups
The security groups are defined in the Terraform configuration. Ensure that the ingress rules match your requirements for SSH and application access.

#### VPC Configuration
The Terraform configuration assumes the use of the default VPC in the `us-east-2` region. If you are using a custom VPC, update the Terraform configuration accordingly.

