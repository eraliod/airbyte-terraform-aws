# pull the aws iam user created for airbyte to interact with the s3 bucket from the ssm parameter store
data "aws_ssm_parameter" "airbyte_poc_user_access_key_id" {
  name = "/airbyte/poc/user_access_key_id"
}
data "aws_ssm_parameter" "airbyte_poc_user_secret_access_key" {
  name = "/airbyte/poc/user_secret_access_key"
}
resource "airbyte_destination_s3" "airbyte_poc_s3_destination" {
  name = "analytics-sandbox S3 destination"

  configuration = {
    access_key_id       = data.aws_ssm_parameter.airbyte_poc_user_access_key_id.value
    secret_access_key   = data.aws_ssm_parameter.airbyte_poc_user_secret_access_key.value
    s3_bucket_name      = var.airbyte_poc_s3_bucket
    s3_bucket_region    = "us-east-2"
    s3_bucket_path      = "$${NAMESPACE}"
    s3_filename_pattern = "$${STREAM_NAME}/$${YEAR}_$${MONTH}_$${DAY}"
    s3_path_format      = "$${STREAM_NAME}/$${YEAR}_$${MONTH}_$${DAY}"
    format = {
      csv_comma_separated_values = {
        compression = {
          gzip = {
            compression_type = "GZIP"
          }
        }
        flattening = "Root level flattening"
      }
    }
  }
  workspace_id = var.workspace_id
}