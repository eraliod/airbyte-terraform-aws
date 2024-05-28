# bucket for airbyte extract load data
resource "aws_s3_bucket" "airbyte_poc" {
  bucket = "kin-airbyte-poc"
}
