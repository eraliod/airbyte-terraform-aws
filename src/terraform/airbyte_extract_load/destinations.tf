# create s3 destination for airbyte data
resource "airbyte_destination_s3" "airbyte_poc_s3_destination" {
  name = "airbyte poc S3 destination"

  configuration = {
    access_key_id       = var.airbyte_poc_user_access_key_id
    secret_access_key   = var.airbyte_poc_user_secret_access_key
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