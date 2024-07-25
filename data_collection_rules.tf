resource "azurerm_monitor_data_collection_rule" "vm_insight" {
  name                = "dcr-prd-all-VmInsights-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  tags                = var.tags
  description         = "Central DCR to collect performance counter metrics and dependency agent data for azure monitor"

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

}

resource "azurerm_monitor_data_collection_rule" "event_log" {
  name                = "dcr-prd-win-EventLogBasic-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  kind                = "Windows"
  tags                = var.tags
  description         = "Collects EventIDs 55 and 6008 from the EventLog"

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
      name    = "EventLog"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "System!*[System[EventID=55]]",
        "System!*[System[EventID=6008]]",
        "System!*[System[Provider[@Name='Microsoft-Windows-Time-Service'] and (EventID=36) and Level=3]]",
      ]
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "dcr-prd-ux-Syslog-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  kind                = "Linux"
  tags                = var.tags
  description         = "Collect syslog data for security monitoring"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace.id
      name                  = var.log_analytics_workspace.name
    }
  }

  data_sources {
    syslog {
      name           = "Syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "user"]
      log_levels     = ["*"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = [var.log_analytics_workspace.name]
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_data_collection_rule" "custom_log" {
  name                        = "dcr-prd-win-CustomLog-01"
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location
  tags                        = var.tags
  description                 = "Collect custom log data for monitoring"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace.id
      name                  = var.log_analytics_workspace.name
    }
  }

  data_flow {
    streams       = ["Custom-Text_Win_CL"]
    destinations  = [var.log_analytics_workspace.name]
    output_stream = "Custom-CustomLog_Win_CL"
    transform_kql = "source"
  }

  data_sources {
    log_file {
      name          = "Custom-Text_Win_CL"
      format        = "text"
      streams       = ["Custom-Text_Win_CL"]
      file_patterns = ["c:\\program files\\ud\\logs\\*.log"]
      settings {
        text {
          record_start_timestamp_format = "ISO 8601"
        }
      }
    }
  }

  stream_declaration {
    stream_name = "Custom-Text_Win_CL"
    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "RawData"
      type = "string"
    }

  }
  depends_on = [azapi_resource.data_collection_logs_table]
}
