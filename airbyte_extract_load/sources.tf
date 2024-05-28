# pull the /airbyte/poc/bingads_client_id from ssm parameter store
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