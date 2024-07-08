resource "airbyte_connection" "airbyte_poc_pypi_to_s3" {
  name                                 = "PyPI to S3"
  source_id                            = airbyte_source_pypi.airbyte_poc_pypi_source.source_id
  destination_id                       = airbyte_destination_s3.airbyte_poc_s3_destination.destination_id
  namespace_definition                 = "custom_format"
  namespace_format                     = "pypi"
  non_breaking_schema_updates_behavior = "propagate_columns"
  status                               = "active"
  schedule = {
    schedule_type   = "cron"
    cron_expression = "0 0 12 * * ?"
  }
  configurations = {
    streams = [
      {
        name                  = "project"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      },
      {
        name                  = "release"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      },
      {
        name                  = "stats"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      }
    ]
  }
}
/* 
----
Commenting out block to disable it in base poc. User can choose to enable
the bing ads connection if they have a bing account and the necessary secrets
----

resource "airbyte_connection" "airbyte_poc_bingads_to_s3" {
  name                                 = "Bing Ads to S3"
  source_id                            = airbyte_source_bing_ads.airbyte_poc_bingad_source.source_id
  destination_id                       = airbyte_destination_s3.airbyte_poc_s3_destination.destination_id
  namespace_definition                 = "custom_format"
  namespace_format                     = "bing_ads"
  non_breaking_schema_updates_behavior = "propagate_columns"
  status                               = "active"
  schedule = {
    schedule_type   = "cron"
    cron_expression = "0 0 12 * * ?"
  }
  configurations = {
    streams = [
      {
        name                  = "ad_performance_report_daily"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      },
      {
        name                  = "keyword_performance_report_daily"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      },
      {
        name                  = "user_location_performance_report_daily"
        sync_mode             = "full_refresh_overwrite"
        destination_sync_mode = "overwrite"
      }
    ]
  }
}
*/