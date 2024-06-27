# bucket for airbyte extract load data
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "airbyte_poc" {
  bucket = "airbyte-poc-${random_id.bucket_suffix.hex}"
}
