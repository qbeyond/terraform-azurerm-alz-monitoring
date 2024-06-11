resource "azurerm_monitor_data_collection_rule" "vm_insight" {
  name                = "dcr-prd-all-VmInsights-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  tags                = var.tags

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

resource "azurerm_monitor_data_collection_rule" "event_log" {
  name                = "dcr-prd-win-EventLogBasic-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  kind                = "Windows"
  tags                = var.tags

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

resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "dcr-prd-ux-Syslog-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  kind                = "Linux"
  description         = "Collect syslog data for security monitoring"
  tags                = var.tags

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