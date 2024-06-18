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
      name           = "EventLog"
      streams        = ["Microsoft-Event"]
      x_path_queries = ["Application!*[System[EventID=55]]", "Application!*[System[EventID=6008]]"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  description = "Collects EventIDs 55 and 6008 from the EventLog"
}

resource "azurerm_monitor_data_collection_rule" "event_log_security" {
  name                = "dcr-prd-win-EventLogSecurity-01"
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
    streams      = ["Microsoft-SecurityEvent"]
    destinations = [var.log_analytics_workspace.name]
  }

  data_sources {
    windows_event_log {
      name    = "EventLog"
      streams = ["Microsoft-SecurityEvent"]
      # Copied from "Windows Security Events via AMA" sentinel data connector
      x_path_queries = [
        "Security!*[System[(EventID=1, 299, 300, 324, 340, 403, 404, 410, 411, 412, 413, 431, 500, 501, 1100)]]",
        "Security!*[System[(EventID=1102, 1107, 1108, 4608, 4610, 4611, 4614, 4622, 4624, 4625, 4634, 4647, 4648, 4649, 4657)]]",
        "Security!*[System[(EventID=4661, 4662, 4663, 4665, 4666, 4667, 4688, 4670, 4672, 4673, 4674, 4675, 4689, 4697, 4700)]]",
        "Security!*[System[(EventID=4702, 4704, 4705, 4716, 4717, 4718, 4719, 4720, 4722, 4723, 4724, 4725, 4726, 4727, 4728)]]",
        "Security!*[System[(EventID=4729, 4733, 4732, 4735, 4737, 4738, 4739, 4740, 4742, 4744, 4745, 4746, 4750, 4751, 4752)]]",
        "Security!*[System[(EventID=4754, 4755, 4756, 4757, 4760, 4761, 4762, 4764, 4767, 4768, 4771, 4774, 4778, 4779, 4781)]]",
        "Security!*[System[(EventID=4793, 4797, 4798, 4799, 4800, 4801, 4802, 4803, 4825, 4826, 4870, 4886, 4887, 4888, 4893)]]",
        "Security!*[System[(EventID=4898, 4902, 4904, 4905, 4907, 4931, 4932, 4933, 4946, 4948, 4956, 4985, 5024, 5033, 5059)]]",
        "Security!*[System[(EventID=5136, 5137, 5140, 5145, 5632, 6144, 6145, 6272, 6273, 6278, 6416, 6423, 6424, 8001, 8002)]]",
        "Security!*[System[(EventID=8003, 8004, 8005, 8006, 8007, 8222, 26401, 30004)]]",
        "Microsoft-Windows-AppLocker/EXE and DLL!*[System[(EventID=8001, 8002, 8003, 8004)]]",
        "Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005, 8006, 8007)]]"
      ]
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
  location            = var.log_analytics_workspace.location
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
