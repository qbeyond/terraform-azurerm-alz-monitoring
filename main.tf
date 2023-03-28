resource "azurerm_log_analytics_datasource_windows_event" "application" {
  name                = "lad-application"
  resource_group_name = local.law_rg
  workspace_name      = local.law_name
  event_log_name      = "Application"
  event_types         = ["Error", "Warning", "Information"]
}

resource "azurerm_log_analytics_datasource_windows_event" "system" {
  name                = "lad-system"
  resource_group_name = local.law_rg
  workspace_name      = local.law_name
  event_log_name      = "System"
  event_types         = ["Error", "Warning", "Information"]
}

module "vm_insights" {
  source  = "qbeyond/log-analytics-VMInsights/azurerm"
  version = "1.0.2"
  log_analytics_workspace = {
    id                  = var.law_id
    name                = local.law_name
    resource_group_name = local.law_rg
    location            = var.location
  }

  depends_on = [
    azurerm_log_analytics_datasource_windows_event.application,
    azurerm_log_analytics_datasource_windows_event.system
  ]
}

resource "azurerm_monitor_action_group" "action_group" {
  name                = "EventPipelineCentral_AG_1"
  resource_group_name = local.law_rg
  short_name          = "monitorhook"

  webhook_receiver {
    name                    = var.webhook_name
    service_uri             = var.webhook_service_uri
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "rules" {
  for_each = local.rules
  name                = each.key
  location            = var.location
  resource_group_name = local.law_rg
  action {
    action_group = [azurerm_monitor_action_group.action_group.id]
  }
  data_source_id = var.law_id
  description    = each.value.description
  enabled        = true
  # Count all requests with server error result code grouped into 5-minute bins
  query       = file(each.value.query_path)
  severity    = 1
  frequency   = 5
  time_window = 2880
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
