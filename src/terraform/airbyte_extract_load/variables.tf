variable "workspace_id" {
  type        = string
  description = "the workspece id GUID for the airbyte server's default workspace"
}

variable "airbyte_poc_s3_bucket" {
  type        = string
  description = "bucket name for the airbyte extract load data"
}

variable "airbyte_poc_ec2_instance_ip" {
  type        = string
  description = "the public ip address of the ec2 instance"
}

variable "airbyte_poc_user_access_key_id" {
  type = string
  description = "id of the airbyte poc user configured to write into s3"
  sensitive = true
}

variable "airbyte_poc_user_secret_access_key" {
  type = string
  description = "secret for the airbyte poc user configured to write into s3"
  sensitive = true
}