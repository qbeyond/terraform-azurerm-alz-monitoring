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

  scopes      = [var.log_analytics_workspace.id]
  description = each.value.description
  enabled     = true
  severity    = 0

  evaluation_frequency = "PT5M"
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