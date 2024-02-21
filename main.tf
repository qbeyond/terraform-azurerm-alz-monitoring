data "azurerm_subscription" "current" {
}

resource "azurerm_monitor_data_collection_rule" "event_log" {
  name                        = "dcr-prd-all-EventLogBasic-01"
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location
  kind                        = "Windows"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace.id
      name                  = var.log_analytics_workspace.name
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = [var.log_analytics_workspace.name]
  }
  
  data_sources {
    windows_event_log {
      name     = "EventLog"
      streams  = ["Microsoft-Event"]
      x_path_queries = ["Application!*[System[EventID=55]]", "Application!*[System[EventID=6008]]"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  description = "Collects EventIDs 55 and 6008 from the EventLog"
}

resource "azurerm_monitor_data_collection_rule" "vm_insight" {
  name                        = "dcr-prd-all-VmInsights-01"
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace.id
      name                  = var.log_analytics_workspace.name
    }
  }

  data_flow {
    streams      = ["Microsoft-ServiceMap"]
    destinations = [var.log_analytics_workspace.name]
  }

  data_flow { 
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = [var.log_analytics_workspace.name]
  }

  data_sources {
    extension {
      extension_name     = "DependencyAgent"
      input_data_sources = []
      name               = "DependencyAgent"
      streams            = ["Microsoft-ServiceMap"]
    }

    performance_counter {
        counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
        name                          = "VMInsightsPerfCounters"
        sampling_frequency_in_seconds = 60
        streams                       = ["Microsoft-InsightsMetrics"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  description = "Central DCR to collect performance counter metrics and dependency agent data for azure monitor"
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
