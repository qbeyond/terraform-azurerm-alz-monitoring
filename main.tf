data "azurerm_subscription" "current" {
}

resource "azurerm_monitor_action_group" "eventpipeline" {
  count               = var.event_pipeline_config.enabled ? 1 : 0
  name                = "EventPipelineCentral_AG_1"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "monitorhook"
  tags                = var.tags

  webhook_receiver {
    name                    = var.event_pipeline_config.name
    service_uri             = replace(var.event_pipeline_config.service_uri, "{{secret}}", var.secret)
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each            = local.rules
  name                = each.key
  location            = var.log_analytics_workspace.location
  resource_group_name = var.log_analytics_workspace.resource_group_name
  tags                = var.tags

  action {
    action_groups = local.action_group
  }

  scopes                = [var.log_analytics_workspace.id]
  description           = each.value.description
  enabled               = true
  severity              = 0
  skip_query_validation = true

  evaluation_frequency = each.value.frequency
  window_duration      = each.value.time_window
  criteria {
    query                   = file(each.value.query_path)
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dimension {
      name     = "RawData"
      operator = "Include"
      values   = ["*"]
    }

    resource_id_column = "_ResourceId"
  }
  target_resource_types = [
    "microsoft.compute/virtualmachines",
    "microsoft.hybridcompute/machines",
    "microsoft.compute/virtualmachinescalesets"
  ]
}

# TODO: fix naming, add more possible endpoints via param
resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "dce-dev-${var.log_analytics_workspace.location}-LawEndpoint-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
}


resource "azapi_resource" "data_collection_logs_table" {
  name      = "CustomLog_Win_CL"
  parent_id = var.log_analytics_workspace.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = jsonencode(
    {
      "properties" : {
        "schema" : {
          "name" : "CustomLog_Win_CL",
          "columns" : [
            {
              "name" : "TimeGenerated",
              "type" : "datetime",
              "description" : "The time at which the data was generated"
            },
            {
              "name" : "RawData",
              "type" : "string",
              "description" : "The data from the file"
            }
          ]
        },
        "retentionInDays" : 30,
        "totalRetentionInDays" : 30
      }
    }
  )
}
