# AWS Terraform Documentation

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

<details>
<summary><b>Expand to learn more about configuring pre-commit</b><b style="color: orange;"> [STRONGLY RECOMMENDED for developers]</b></summary>
This project utilizes pre-commit hooks to enforce code quality and assist with reviews

Merges will not be allowed unless these hooks pass

It is strongly recommended to use pre-commit locally to streamline reviews

### Install pre-commit

#### PIP

```shell
pip install pre-commit
```

#### Homebrew

```shell
brew install pre-commit
```

### Enable pre-commit

```shell
pre-commit install
```

### Automatically enable pre-commit on cloned repos

```shell
git config --global init.templateDir ~/.git-template
pre-commit init-templatedir ~/.git-template
```

</details>

## Summary
The code in this repository establishes an airbyte server, all of its necessary infrastructure, and a sample pipeline (source, destination, and connection).

It uses terraform to create all infrastructure as code. This is broken down into two modules.
1. `aws_infrastructure` - stands up a fully functional Airbyte server
2. `airbyte_extract_load` - creates some sample airbyte resources to avoid having to configure in the UI

Note that this primarily meant to serve as a proof of concept (POC) for testing Airbyte. The code is in minimum viable product (MVP) state.

## Set-Up Instructions
Skip if you have aws cli and terraform >= v1.9.0 installed and configured

### Install Prerequisites

- Install and configure the aws cli
   - `brew install aws`
   - If this is your first time logging into aws. Check the [official documentation](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)

- Install terraform cli 
   - brew's default tap is not up-to-date with terraform releases, so please follow the [instructions from hashicorp](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Run Setup
The design decision to use a remote backend for terraform means that we need some basic infrastructure for terraform to function.

All of this can be accomplished with the script in `src/setup/`

It generates an aws cloudformation stack that contains:
- a bucket (to store the state file remotely)
- a dynamodb table (to manage state locks)
- a role (to connect to the backend programatically)
- an iam policy (to ensure the role can access the resources it needs)


1. Log into the aws cli 
   - `aws sso login`
2. run the script 
   - `./src/setup/tf-manage-backend.sh`
      - When running the script, *you will need to provide the three arguments in order*
         - **AppName**: The name of **your** project (ex. "airbyte_poc")
         - **GithubRepo**: **Your** org/repo where the CI is executing from (ex. "eraliod/airbyte-terraform-aws")
         - **UniqueBucketId**: A unique identifier for **your** bucket name, since s3 bucket names are globally unique (ex. "de-prod")
         - ex. `./src/setup/tf-manage-backend.sh airbyte_poc eraliod/airbyte-terraform-aws de-prod`  

### Define Secrets
Secrets need to be manually defined somewhere secure. For this project, I used the AWS Parameter Store
1. Open the AWS Console > System Manager > Parameter Store
2. Create the following secrets:
   - `/airbyte/poc/server_admin_password` - Password to enter the Airbyte Server UI (running on EC2)
   - `/airbyte/poc/postgres_db_user_password` - Password for the RDS postgres db our scripts create to serve as a storage for the Airbyte server metadata

### Run Terraform
1. Go to the terraform directory
   - `cd /src/terraform`
2. Initialize terraform
   - `terraform init`
2. Run terraform plan and apply
   - `terraform plan --out=plan.tfplan`
   - `terraform apply plan.tfplan`

It will take some time for the first run. The longest portion appears to be the rds instance that is used to store the airbyte metadata

## Usage

### Connecto the the Airbyte Server
The Airbyte server can be accessed via port 8000 in the EC2 instance
1. Open the AWS Console > EC2
2. Find the instance named "airbyte-poc-ec2"
3. Open the public IP address and add `:8000` to the URL *(Hint: ensure you are using http, not https in the url)*
   - ex: http://ec2-3-144-179-240.us-east-2.compute.amazonaws.com:8000
4. Use "admin" as the username along with the password you stored in the parameter store.

## Section Documentation

### AWS Infrastructure
Creates all the aws resources needed for the airbyte server to function:
- a basic EC2 instance with open ports for airbyte and rds
- an aurora postgres database configured as the back-end for airbyte
   -  airbyte stores configurations here, so state will be saved even if the ec2 is re-created
- an iam role for the airbyte server
- an s3 bucket for airbyte to store data
- a user for the data bucket so airbyte can write data into s3

### Airbyte Connections
Creates some sample connections to get started with using Terraform to manage Airbyte. This is completely optional, as the Airbyte server is fully functional at this point and these things can be set up easily through the UI. 
However, I believe in the value of infrastructure as code (IaC), so the module gives working examples of how to configure airbyte connections through terraform.


### Optional Configurations
#### AWS Region
There are several instances in this project where you will find `us-east-2`. You may change to any region as long as it is consistent throughout the project.

#### Security Groups
The security groups are defined in the Terraform configuration. Ensure that the ingress rules match your requirements for SSH and application access. There is a basic configuration in place, but it is too permissive for anything more than a proof of concept.

#### VPC Configuration
The Terraform configuration assumes the use of the default VPC for the region. If you are using a custom VPC, update the Terraform configuration accordingly.

#### Bing Ads Source
There is a sample source that uses a Bing Ads account to move data to S3 buckets.
It is currently commented out in the sources and connections files in the `airbyte_extract_load` project.
If you want to activate it, uncomment the code and add the following to the AWS SSM Parameter Store
   - `/airbyte/poc/bingads_client_id`: Bing Ads Client ID
   - `/airbyte/poc/bingads_developer_token`: Bing Ads Developer Token
   - `/airbyte/poc/bingads_client_secret`: Bing Ads Client Secret
   - `/airbyte/poc/bingads_refresh_token`: Bing Ads API Refresh Token
