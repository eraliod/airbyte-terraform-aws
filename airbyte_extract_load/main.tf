# main terraform file for the airbyte infrastructure
terraform {
  backend "s3" {
    bucket         = "airbyte-poc-tf-state-de"  # your unique bucket id
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
