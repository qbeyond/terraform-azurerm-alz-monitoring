data "azurerm_subscription" "current" {
}

resource "azurerm_log_analytics_datasource_windows_event" "application" {
  name                = "lad-application"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  workspace_name      = var.log_analytics_workspace.name
  event_log_name      = "Application"
  event_types         = ["Error", "Warning", "Information"]
}

resource "azurerm_log_analytics_datasource_windows_event" "system" {
  name                = "lad-system"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  workspace_name      = var.log_analytics_workspace.name
  event_log_name      = "System"
  event_types         = ["Error", "Warning", "Information"]
}

module "vm_insights" {
  source  = "qbeyond/log-analytics-VMInsights/azurerm"
  version = "1.0.2"
  log_analytics_workspace = {
    id                  = var.log_analytics_workspace.id
    name                = var.log_analytics_workspace.name
    resource_group_name = var.log_analytics_workspace.resource_group_name
    location            = var.log_analytics_workspace.location
  }

  depends_on = [
    azurerm_log_analytics_datasource_windows_event.application,
    azurerm_log_analytics_datasource_windows_event.system
  ]
}

resource "azurerm_monitor_action_group" "eventpipeline" {
  count = var.event_pipeline_config.enabled ? 1 : 0
  name                = "EventPipelineCentral_AG_1"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "monitorhook"

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
