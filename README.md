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
Skip if you have `aws cli` and `terraform >= v1.9.0` installed and configured

### Install Prerequisites

- Install and configure the aws cli
   - `brew install aws`
   - If this is your first time logging into aws. Check the [official documentation](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)

- Install terraform cli 
   - brew's default tap is not up-to-date with terraform releases, so please follow the [instructions from hashicorp](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Define Secrets
Secrets need to be defined somewhere secure. For this project, I used the AWS Parameter Store

   - `/airbyte/poc/server_admin_password` - Password to enter the Airbyte Server UI (running on EC2)
   - `/airbyte/poc/postgres_db_user_password` - Password for the RDS postgres db our scripts create to 
  
<details>
<summary>Programatic method through aws cli</summary>

```sh
aws ssm put-parameter \
    --name "/airbyte/poc/server_admin_password" \
    --value "abcde123" \
    --type "SecureString" \
    --overwrite
```
```sh
aws ssm put-parameter \
    --name "/airbyte/poc/postgres_db_user_password" \
    --value "abcde123" \
    --type "SecureString" \
    --overwrite
```
</details>
<br>

<details>
<summary>Manual method through aws console / ui</summary>

1. Open the AWS Console > System Manager > Parameter Store
2. Create the two secrets listed above
   - Take care to ensure the name of the secret matches (include the forward slashes)
</details>

### Run Terraform
1. Go to the terraform directory
   - `cd /src/terraform`
2. Initialize terraform
   - `terraform init`
2. Run terraform plan and apply
   - `terraform plan --out=plan.tfplan`
   - `terraform apply plan.tfplan`

It will take some time for the first run. The longest portion appears to be the rds instance that is used to store the airbyte metadata

### Troubleshooting

Generally speaking, in my experience with Terraform, there are times where it just needs to be re-run. If terraform is configured correctly, it is idempotent. Simply running plan and apply will fix most issues.

#### Known Issues
**The ec2 instance may fail to initialize properly if the rds instance is not ready.** In that case, we do not need to start over. Simply tell terraform that the ec2 instance needs to be rebuilt:

`terraform taint module.aws_infrastructure.aws_instance.ec2_instance `

Then run terraform plan and apply again

## Usage

### Connecto the the Airbyte Server
The Airbyte server can be accessed via port 8000 in the EC2 instance
1. Open the AWS Console > EC2
2. Find the instance named "airbyte-poc-ec2"
3. Open the public IP address and add `:8000` to the URL *(Hint: ensure you are using http, not https in the url)*
   - ex: http://ec2-3-144-179-240.us-east-2.compute.amazonaws.com:8000
4. Use "admin" as the username along with the password you stored in the parameter store.

Your server will already have a source and destination with a connection ready to go. You may open the connection and click the "sync now" button at the top right. This will populate PyPi data to your s3 destination.

### Next Steps
Feel free to create connections manually through the UI or explore other terraform connectors from the [airbyte terraform provider](https://registry.terraform.io/providers/airbytehq/airbyte/latest/docs)

Your destination is set up to save tables as csv.gz files. Another step could be to explore loading that data to a database (such as Redshift) or cataloguing it with aws glue to make it querieable by athena.

## Terraform Module Documentation

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

#### Backend
The `src/terraform/main.tf` file is configured to use a local backend by default. 

This is the easiest method of deployment for the POC. But has shortcomings for durability. There is a separate branch of this project where I am working on adapting an s3 backend and github actions (A setup I am using in other projects but is not ready in this repo)

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
