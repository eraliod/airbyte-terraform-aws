terraform {
  backend "s3" {
    bucket         = "airbyte-poc-tf-state"
    key            = "aws_infrastructure.tfstate"
    region         = "us-east-2"
    dynamodb_table = "airbyte_poc_tf_state_lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
