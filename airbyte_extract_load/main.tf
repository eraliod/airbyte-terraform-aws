# main terraform file for the airbyte infrastructure
terraform {
  backend "s3" {
    bucket         = "airbyte-poc-tf-state"
    key            = "airbyte.tfstate"
    region         = "us-east-2"
    dynamodb_table = "airbyte_poc_tf_state_lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.5.0"
    }
  }
}

# pull the password from ssm parameter store in aws
data "aws_ssm_parameter" "airbyte_db_password" {
  name = "/airbyte/poc/server_admin_password"
}

# pull the ip address of the airbyte server from the sssm parameter store in aws
data "aws_ssm_parameter" "airbyte_server_ip" {
  name = "/airbyte/poc/ec2_instance_ip"
}

provider "airbyte" {
  username   = "data-dolphin-admin"
  password   = data.aws_ssm_parameter.airbyte_db_password.value
  server_url = "http://${data.aws_ssm_parameter.airbyte_server_ip.value}:8006/v1"
}

provider "aws" {
  region = "us-east-2"
}

variable "workspace_id" {
  type    = string
  default = "63c5eb65-2385-4a0a-ac35-bed083e0ac1b"
}

data "terraform_remote_state" "aws_infrastructure" {
  backend = "s3"
  config = {
    bucket = "airbyte-poc-tf-state"
    key    = "aws_infrastructure.tfstate"
    region = "us-east-2"
  }
}

variable "airbyte_poc_s3_bucket" {
  type = string
  default = data.terraform_remote_state.aws_infrastructure.outputs.bucket_name
}
