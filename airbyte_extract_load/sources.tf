# use pypi as demo source since it does not require API authentication
resource "airbyte_source_pypi" "airbyte_poc_pypi_source" {
  configuration = {
    project_name = "async"
    version      = "0.6.2"
  }
  name         = "pypi"
  workspace_id = var.workspace_id
}

/* 
----
Commenting out block to disable it in base poc. User can choose to enable
the bing ads connection if they have a bing account and the necessary secrets
----

# pull the /airbyte/poc/bingads_* secrets from ssm parameter store
data "aws_ssm_parameter" "airbyte_poc_bingads_client_id" {
  name = "/airbyte/poc/bingads_client_id"
}
data "aws_ssm_parameter" "airbyte_poc_bingads_developer_token" {
  name = "/airbyte/poc/bingads_developer_token"
}
data "aws_ssm_parameter" "airbyte_poc_bingads_refresh_token" {
  name = "/airbyte/poc/bingads_refresh_token"
}
data "aws_ssm_parameter" "airbyte_poc_bingads_client_secret" {
  name = "/airbyte/poc/bingads_client_secret"
}

resource "airbyte_source_bing_ads" "airbyte_poc_bingad_source" {
  configuration = {
    client_id          = data.aws_ssm_parameter.airbyte_poc_bingads_client_id.value
    developer_token    = data.aws_ssm_parameter.airbyte_poc_bingads_developer_token.value
    lookback_window    = 6
    refresh_token      = data.aws_ssm_parameter.airbyte_poc_bingads_refresh_token.value
    client_secret      = data.aws_ssm_parameter.airbyte_poc_bingads_client_secret.value
    reports_start_date = "2024-05-01"
  }
  name         = "Bing Ads"
  workspace_id = var.workspace_id
}
*/
