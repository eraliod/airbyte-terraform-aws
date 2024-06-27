# AWS Terraform Documentation
The code in this repository establishes an airbyte server, all of its necessary infrastructure, and a few connections for data extraction and loading.

It uses terraform to create all infrastructure as code. Once the pre-requisites have been taken care of, any code updates to the main branch will trigger terraform to plan and apply changes.

Note that this is a proof of concept (POC) and the code is in minimum viable product (MVP) state.

## Set-Up Instructions
There are a few reqiurements to get everything stood up. These are separated into two sections: **[AWS Infrastructure](#aws-infrastructure)** and **[Airbyte Connections](#airbyte-connections)**.
It is important to successfully apply the AWS Infrastructure terraform project found in the aws_infrastructure directory.
Once this is complete, the `airbyte_extract_load/variables.tf` file should be updated with values corresponding to resources created by the AWS Infrastructure project.

### AWS Infrastructure
Creates all the aws resources needed for the airbyte server to function:
- a basic EC2 instance with open ports for airbyte and connecting to the internet
- an aurora postgres database configured as the back-end for airbyte (airbyte stores configurations here)
- a simple iam role for airbyte
- a simple s3 bucket for airbyte to store data

#### AWS AIM user for Terraform
Terraform will need to have privilege to create aws resources and interact with the s3 bucket hosting the state files. Since this is a POC, the user will have broad access, but it is advised that privileges be narrowed and AWS Roles be considered instead.

1. Create a new user `airbyte-poc-user` in aws iam
2. Attach standard policies to the user
   - AmazonDynamoDBFullAccess
   - AmazonEC2FullAccess
   - AmazonRDSFullAccess
   - AmazonS3FullAccess
   - AmazonSSMFullAccess
   - IAMFullAccess
3. Create an Access Key (access_key_id & secret_access_key)

#### GitHub Secrets
Configure the following secrets in your environment variables (for local development) and the GitHub repository > settings > secrets > actions to run it in CI:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.

#### SSM Parameter Store Secrets
   For the aws infrastructure
   - `/airbyte/poc/postgres_db_user_password`: The RDS Postgres db password
   - `/airbyte/poc/server_admin_password`: The Airbyte server basic authentication password
   - `/airbyte/poc/server_admin_username`: The Airbyte server basic authentication username

#### Terraform Backend Bucket
This bucket will be used to store the Terraform state file.

Create an S3 bucket named `airbyte-poc-tf-state-[id]` for Terraform backend. `[id]` refers to your own identifier because S3 bucket names must be globaly unique.

Update this value in the main.tf files in the project before running terraform.

#### DynamoDB Table for State Lock
This table will be used for state locking to prevent concurrent runs of Terraform.

Create a DynamoDB table named `airbyte_poc_tf_state_lock` with a partition key named `LockID` of type String.

### Optional Configurations
#### AWS Region
There are several instances in this project where you will find `us-east-2`. You may change to any region as long as it is consistent.

#### Security Groups
The security groups are defined in the Terraform configuration. Ensure that the ingress rules match your requirements for SSH and application access.

#### VPC Configuration
The Terraform configuration assumes the use of the default VPC for the region. If you are using a custom VPC, update the Terraform configuration accordingly.

#### Bing Ads Source
There is a sample source that uses a Bing Ads account to move data to S3 buckets.
It is currently commented out in the sources and connections files in the airbyte_extract_load project.
If you want to activate it, uncomment the code and add the following to the AWS SSM Parameter Store
   - `/airbyte/poc/bingads_client_id`: Bing Ads Client ID
   - `/airbyte/poc/bingads_developer_token`: Bing Ads Developer Token
   - `/airbyte/poc/bingads_client_secret`: Bing Ads Client Secret
   - `/airbyte/poc/bingads_refresh_token`: Bing Ads API Refresh Token

### Airbyte Connections
Creates some sample connections to get started with using Terraform to manage Airbyte. This is completely optional, as the Airbyte server is fully functional at this point and these thigns can be set up easily through the UI. However, I believe in the value of infrastructure as code (IaC).

#### Workspace ID
When the Airbyte Server was installed, it was given a UUID as the workspace_id value. Though this could be queried through an API, the simplest way to get this is to simply log into the server.
Go to the AWS EC2 console to check the public IP for the server. visit https://[airbyte-server-public-id]:8000 and log in with the credentials you saved into the SSM Parameter store.
In the URL at the top of your browser, you will find the UUID as a random GUI (ex. "63c5eb65-2385-4a0a-ac35-bed083e0ac1b").
Copy this into `airbyte_extract_load/variables.tf`.

#### S3 Data Bucket
Because S3 bucket names must be globally unique, we used a randomize[r in the `aws_infrastructure/s3.tf` file.
Visit the S3 aws console and look for a bucket named: `"airbyte-poc-[random-hex]"`.
Save the bucket name into `airbyte_extract_load/variables.tf`.