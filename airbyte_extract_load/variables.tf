# save your airbyte workspace_id here
# it can be found in the url of the airbyte server once you log into it
variable "workspace_id" {
  type    = string
  default = "f0053ef5-13af-4419-96eb-33491c1616aa"
}

# save your data bucket name here from the aws_infrastructure project.
# it will be named `airbyte-poc-[random hex]`
variable "airbyte_poc_s3_bucket" {
  type    = string
  default = "enter bucket name here"
}