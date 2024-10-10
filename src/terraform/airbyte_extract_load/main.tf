terraform {
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
data "aws_ssm_parameter" "airbyte_server_admin_password" {
  name = "/airbyte/poc/server_admin_password"
}

provider "airbyte" {
  username   = "admin"
  password   = data.aws_ssm_parameter.airbyte_server_admin_password.value
  server_url = "http://${var.airbyte_poc_ec2_instance_ip}:8001/api/public/v1"
}

provider "aws" {
  region = "us-east-2"
}
