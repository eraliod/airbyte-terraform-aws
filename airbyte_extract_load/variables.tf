# save your airbyte workspace_id here
# it can be found in the url of the airbyte server once you log into it
variable "workspace_id" {
  type    = string
  default = "63c5eb65-2385-4a0a-ac35-bed083e0ac1b"
}

# save your data bucket name here from the aws_infrastructure project.
# it will be named `airbyte-poc-[random hex]`
variable "airbyte_poc_s3_bucket" {
  type    = string
  default = "enter bucket name here"
}