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
  description         = "Collect syslog data for monitoring - Loglevel Debug"

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
      facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "user", "syslog"]
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


resource "azurerm_monitor_data_collection_rule" "syslog_notice" {
  name                = "dcr-prd-ux-Syslog-02"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  kind                = "Linux"
  tags                = var.tags
  description         = "Collect syslog data for monitoring - Loglevel Notice"

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
      facility_names = ["lpr", "mail", "news", "syslog", "uucp", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "ftp", "clock"]
      log_levels     = ["Notice"]
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

resource "azurerm_monitor_data_collection_rule" "additional_data_collection_rules" {
  for_each            = var.additional_data_collection_rules
  name                = each.value.name
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  kind                = each.value.kind
  description         = each.value.description
  tags                = merge(var.tags, try(each.value.tags, {}))

  destinations {
    dynamic "azure_monitor_metrics" {
      for_each = try(each.value.destinations.azure_monitor_metrics, null) != null ? [each.value.destinations.azure_monitor_metrics] : []
      content { 
        name = azure_monitor_metrics.value.name 
      }
    }

    dynamic "event_hub" {
      for_each = try(each.value.destinations.event_hub, null) != null ? [each.value.destinations.event_hub] : []
      content {
        name         = event_hub.value.name
        event_hub_id = event_hub.value.event_hub_id
      }
    }

    dynamic "event_hub_direct" {
      for_each = try(each.value.destinations.event_hub_direct, null) != null ? [each.value.destinations.event_hub_direct] : []
      content {
        name         = event_hub_direct.value.name
        event_hub_id = event_hub_direct.value.event_hub_id
      }
    }

    dynamic "log_analytics" {
      for_each = try(each.value.destinations.log_analytics, null) != null ? [each.value.destinations.log_analytics] : []
      content {
        workspace_resource_id = log_analytics.value.workspace_resource_id
        name                  = log_analytics.value.name
      }
    }

    dynamic "monitor_account" {
      for_each = try(each.value.destinations.monitor_account, null) != null ? [each.value.destinations.monitor_account] : []
      content {
        name               = monitor_account.value.name
        monitor_account_id = monitor_account.value.monitor_account_id
      }
    }

    dynamic "storage_blob" {
      for_each = try(each.value.destinations.storage_blob, null) != null ? [each.value.destinations.storage_blob] : []
      content {
        name               = storage_blob.value.name
        storage_account_id = storage_blob.value.storage_account_id
        container_name     = storage_blob.value.container_name
      }
    }

    dynamic "storage_blob_direct" {
      for_each = try(each.value.destinations.storage_blob_direct, null) != null ? [each.value.destinations.storage_blob_direct] : []
      content {
        name               = storage_blob_direct.value.name
        storage_account_id = storage_blob_direct.value.storage_account_id
        container_name     = storage_blob_direct.value.container_name
      }
    }

    dynamic "storage_table_direct" {
      for_each = try(each.value.destinations.storage_table_direct, null) != null ? [each.value.destinations.storage_table_direct] : []
      content {
        name               = storage_table_direct.value.name
        storage_account_id = storage_table_direct.value.storage_account_id
        table_name         = storage_table_direct.value.table_name
      }
    }
  }

  dynamic "data_sources" {
    for_each = try(each.value.data_sources, null) == null ? [] : [each.value.data_sources]
    content {
      dynamic "data_import" {
        for_each = try(data_sources.value.data_import, null) == null ? [] : [data_sources.value.data_import]
        content {
          dynamic "event_hub_data_source" {
            for_each = try(data_import.value.event_hub_data_sources, [])
            content {
              name           = event_hub_data_source.value.name
              stream         = event_hub_data_source.value.stream
              consumer_group = event_hub_data_source.value.consumer_group
            }
          }
        }
      }

      dynamic "extension" {
        for_each = try(data_sources.value.extension, [])
        content {
          extension_name = extension.value.extension_name
          name           = extension.value.name
          streams        = extension.value.streams
        }
      }

      dynamic "iis_log" {
        for_each = try(data_sources.value.iis_log, [])
        content {
          name            = iis_log.value.name
          streams         = iis_log.value.streams
          log_directories = iis_log.value.log_directories
        }
      }

      dynamic "log_file" {
        for_each = try(data_sources.value.log_file, [])
        content {
          name          = log_file.value.name
          streams       = log_file.value.streams
          file_patterns = log_file.value.file_patterns
          format        = log_file.value.format
        }
      }

      dynamic "performance_counter" {
        for_each = try(data_sources.value.performance_counter, [])
        content {
          name                          = performance_counter.value.name
          streams                       = performance_counter.value.streams
          counter_specifiers            = performance_counter.value.counter_specifiers
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
        }
      }

      dynamic "platform_telemetry" {
        for_each = try(data_sources.value.platform_telemetry, [])
        content {
          name    = platform_telemetry.value.name
          streams = platform_telemetry.value.streams
        }
      }

      dynamic "prometheus_forwarder" {
        for_each = try(data_sources.value.prometheus_forwarder, [])
        content {
          name    = prometheus_forwarder.value.name
          streams = prometheus_forwarder.value.streams
        }
      }

      dynamic "syslog" {
        for_each = try(data_sources.value.syslog, [])
        content {
          name           = syslog.value.name
          streams        = try(syslog.value.streams, null)
          facility_names = try(syslog.value.facility_names, null)
          log_levels     = try(syslog.value.log_levels, null)
        }
      }

      dynamic "windows_event_log" {
        for_each = try(data_sources.value.windows_event_log, [])
        content {
          name           = windows_event_log.value.name
          streams        = windows_event_log.value.streams
          x_path_queries = windows_event_log.value.x_path_queries
        }
      }

      dynamic "windows_firewall_log" {
        for_each = try(data_sources.value.windows_firewall_log, [])
        content {
          name    = windows_firewall_log.value.name
          streams = windows_firewall_log.value.streams
        }
      }
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flows
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  identity {
    type         = each.value.identity.type
    identity_ids = try(each.value.identity.identity_ids, null)
  }
}