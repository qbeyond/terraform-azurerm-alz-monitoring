data "azurerm_subscription" "current" {
}

resource "azurerm_monitor_action_group" "eventpipeline" {
  count = var.event_pipeline_config.enabled ? 1 : 0
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

resource "azurerm_monitor_scheduled_query_rules_alert" "this" {
  for_each = local.rules
  name                = each.key
  location            = var.log_analytics_workspace.location
  resource_group_name = var.log_analytics_workspace.resource_group_name
  tags                = var.tags
  action {
    action_group = local.action_group
  }
  data_source_id = var.log_analytics_workspace.id
  description    = each.value.description
  enabled        = true
  # Count all requests with server error result code grouped into 5-minute bins
  query       = file(each.value.query_path)
  severity    = 1
  frequency   = 5
  time_window = each.value.time_window
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
