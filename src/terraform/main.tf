terraform {
  backend "local" {
    path = "terraform.tfstate"
    # backend "s3" {
    # bucket         = "airbyte-poc-tf-state-de"  # your unique bucket id
    # key            = "aws_infrastructure.tfstate"
    # region         = "us-east-2"
    # dynamodb_table = "airbyte_poc_tf_state_lock"
    # encrypt        = true
  }
}

module "aws_infrastructure" {
  source = "./aws_infrastructure"
}

module "airbyte_extract_load" {
  source                             = "./airbyte_extract_load"
  airbyte_poc_s3_bucket              = module.aws_infrastructure.airbyte_poc_s3_bucket
  workspace_id                       = module.aws_infrastructure.airbyte_poc_workspace_id
  airbyte_poc_ec2_instance_ip        = module.aws_infrastructure.airbyte_poc_ec2_instance_ip
  airbyte_poc_user_access_key_id     = module.aws_infrastructure.airbyte_poc_user_access_key_id
  airbyte_poc_user_secret_access_key = module.aws_infrastructure.airbyte_poc_user_secret_access_key
}

# include outputs here to troubleshoot with 'terraform output'
output "aws_infrastructure_outputs" {
  value = {
    airbyte_poc_s3_bucket       = module.aws_infrastructure.airbyte_poc_s3_bucket
    airbyte_poc_workspace_id    = module.aws_infrastructure.airbyte_poc_workspace_id
    airbyte_poc_ec2_instance_ip = module.aws_infrastructure.airbyte_poc_ec2_instance_ip
  }
}