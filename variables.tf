variable "log_analytics_workspace" {
  type = object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
    primary_shared_key  = string
  })
  nullable    = false
  description = <<-DOC
  ```
  Log Analytics Worksapce that all VMs are connected to for monitoring.
  {
    id                  = ID of the Log Analytics Workspace.
    name                = Name of the Log Analytics Workspace.
    resource_group_name = Resource group name of the Log Analytics Workspace.
    location            = Location of the Log Analytics Workspace.
    workspace_id        = Workspace ID of the Log Analytics Workspace.
    primary_shared_key  = Primary shared key of the Log Analytics Workspace.
  }
  ```
  DOC
}

variable "additional_queries" {
  type = map(object({
    query_path                = string
    description               = string
    time_window               = string
    frequency                 = string
    non_productive            = optional(bool, false)
    display_name              = optional(string)
    query_time_range_override = optional(string)
    include_failing_periods   = optional(object({
      minimum_failing_periods_to_trigger_alert = number
      number_of_evaluation_periods             = number
    }))
  }))
  default     = {}
  nullable    = false
  description = <<-DOC
  ```
  List of additional alert rule queries to create with a file path, description and time_window.
  {
    "query_path"                = Path to the kusto query file.
    "description"               = Description of the alert rule.
    "time_window"               = Time window for the alert rule,                       e.g. "PT5M", "P1D",             "P2D".
    "frequency"                 = Frequency of evaluation,                              e.g. "PT5M", "PT15M".
    "non_productive"            = If true,                                              the alert will use the non productive action group.
    "display_name"              = Optional display name for the alert rule. If not set, the resource name will be used.
    "query_time_range_override" = Optional time range override for the query,           e.g. "P1D",  "P2D". If not set, the time_window will be used.
    "include_failing_periods"   = Optional object to include failing periods in the alert rule.
      {
        minimum_failing_periods_to_trigger_alert = number of failing periods to trigger the alert.
        number_of_evaluation_periods             = number of evaluation periods to consider.
      }
  }
  ```
  DOC
}

variable "secret" {
  type        = string
  description = "Value that will replace the placeholder `{{secret}}` in `event_pipeline_config.service_uri`."
  sensitive   = true
  default     = ""
}

variable "secret_integration" {
  type        = string
  description = "Value that will replace the placeholder `{{secret}}` in `event_pipeline_config.service_uri_integration`."
  sensitive   = true
  default     = ""
}

variable "automation_account" {
  type = object({
    name                = string
    id                  = string
    location            = string
    resource_group_name = string
  })
  nullable    = false
  description = <<-DOC
  ```
  Automation account where the resource graph script will be deployed.
  {
    name                = Name of the automation account.
    id                  = ID of the automation account.
    location            = Location of the automation account.
    resource_group_name = Resource group name of the automation account.
  }
  ```
  DOC
}

variable "event_pipeline_config" {
  type = object({
    enabled                 = bool
    name                    = optional(string, "QBY EventPipeline")
    service_uri             = optional(string, "")
    service_uri_integration = optional(string, "")
  })

  description = <<-DOC
  ```
  {
    enabled     = Enable the action group if you want to send data to a monitoring service.
    name        = Name of the alert webhook.
    service_uri = Link to the webhook receiver URL. Must contain the placeholder \"{{secret}}\". This placeholder will be replaced by the secret value from var.secret. This is used to add authentication to the webhook URL as a query parameter.
    service_uri_integration = Same as service_uri for non productive monitoring alerts, the secret value from var.secret_integration will be used here.
  }
  ```
  DOC
  default = {
    enabled = false
  }

  validation {
    condition     = var.event_pipeline_config.enabled ? var.event_pipeline_config.service_uri != null : true
    error_message = "If the config is enabled the service_uri must be set."
  }

  validation {
    condition     = var.event_pipeline_config.enabled ? strcontains(var.event_pipeline_config.service_uri, "{{secret}}") : true
    error_message = "If the config is enabled the service_uri must contain the {{secret}} placeholder."
  }
}

variable "root_management_group_id" {
  type        = string
  description = "The management group that will be scanned by the Import-ResourceGraphToLogAnalytics runbook."
  default     = "alz"
}

variable "tags" {
  type        = map(string)
  description = "Tags that will be assigned to all resources."
  default     = {}
}

variable "additional_regions" {
  type        = set(string)
  description = "Regions for additional data collection endpoints outside of the LAWs region."
  default     = []
}

variable "active_services" {
  type = object({
    active_directory = optional(bool, false)
    managed_os       = optional(bool, false)
    mssql            = optional(bool, false)
  })
  default     = {}
  description = <<-DOC
  ```
  Services to receive event monitoring.
  {
    active_directory = Enable monitoring for Azure AD.
    managed_os       = Enable monitoring for Managed OS.
    mssql            = Enable monitoring for Azure SQL and SQL on VMs.
  }
  ```
  DOC
}

variable "customer_code" {
  description = "Customer code used as an identifier in monitoring alerts. Must be specified when no service URI with customer code is given."
  type        = string
  default     = ""
}

variable "additional_data_collection_rules" {
  type = map(object({
    name        = string
    kind        = optional(string)
    description = optional(string)
    tags        = optional(map(string), {})

    destinations = object({
      azure_monitor_metrics = optional(object({ name = string }), null)
      event_hub             = optional(object({ name = string, event_hub_id = string }), null)
      event_hub_direct      = optional(object({ name = string, event_hub_id = string }), null)
      log_analytics         = optional(object({ name = string, workspace_resource_id = string }), null)
      monitor_account       = optional(object({ name = string, monitor_account_id = string }), null)
      storage_blob          = optional(object({ name = string, storage_account_id = string, container_name = string }), null)
      storage_blob_direct   = optional(object({ name = string, storage_account_id = string, container_name = string }), null)
      storage_table_direct  = optional(object({ name = string, storage_account_id = string, table_name = string }), null)
    })

    data_sources = optional(object({
      data_import = optional(object({
        event_hub_data_sources = list(object({
          name           = string
          stream         = string
          consumer_group = string
        }))
      }), null)

      extension = optional(list(object({
        extension_name = string
        name           = string
        streams        = list(string)
      })), [])

      iis_log = optional(list(object({
        name            = string
        streams         = list(string)
        log_directories = list(string)
      })), [])

      log_file = optional(list(object({
        name          = string
        streams       = list(string)
        file_patterns = list(string)
        format        = string
      })), [])

      performance_counter = optional(list(object({
        name                          = string
        streams                       = list(string)
        counter_specifiers            = list(string)
        sampling_frequency_in_seconds = number
      })), [])

      platform_telemetry = optional(list(object({
        name    = string
        streams = list(string)
      })), [])

      prometheus_forwarder = optional(list(object({
        name    = string
        streams = list(string)
      })), [])

      syslog = optional(list(object({
        name           = string
        streams        = optional(list(string))
        facility_names = optional(list(string))
        log_levels     = optional(list(string))
      })), [])

      windows_event_log = optional(list(object({
        name           = string
        streams        = list(string)
        x_path_queries = list(string)
      })), [])

      windows_firewall_log = optional(list(object({
        name    = string
        streams = list(string)
      })), [])
    }), {})

    data_flow = list(object({
      streams            = list(string)
      destinations       = list(string)
      output_stream      = optional(string)
      built_in_transform = optional(string)
      transform_kql      = optional(string)
    }))

    identity = optional(object({
      type         = optional(string)
      identity_ids = optional(list(string), [])
    }), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        try(v.destinations.azure_monitor_metrics.name, "") != "" ||
        try(v.destinations.event_hub.name, "")             != "" ||
        try(v.destinations.event_hub_direct.name, "")      != "" ||
        try(v.destinations.log_analytics.name, "")         != "" ||
        try(v.destinations.monitor_account.name, "")       != "" ||
        try(v.destinations.storage_blob.name, "")          != "" ||
        try(v.destinations.storage_blob_direct.name, "")   != "" ||
        try(v.destinations.storage_table_direct.name, "")  != ""
      )
    ])
    error_message = "Each DCR must declare at least one destination."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      length(
        toset(compact(concat(
          [try(v.destinations.azure_monitor_metrics.name, null)],
          [try(v.destinations.event_hub.name, null)],
          [try(v.destinations.event_hub_direct.name, null)],
          [try(v.destinations.log_analytics.name, null)],
          [try(v.destinations.monitor_account.name, null)],
          [try(v.destinations.storage_blob.name, null)],
          [try(v.destinations.storage_blob_direct.name, null)],
          [try(v.destinations.storage_table_direct.name, null)]
        )))
      ) == length(
        compact(concat(
          [try(v.destinations.azure_monitor_metrics.name, null)],
          [try(v.destinations.event_hub.name, null)],
          [try(v.destinations.event_hub_direct.name, null)],
          [try(v.destinations.log_analytics.name, null)],
          [try(v.destinations.monitor_account.name, null)],
          [try(v.destinations.storage_blob.name, null)],
          [try(v.destinations.storage_blob_direct.name, null)],
          [try(v.destinations.storage_table_direct.name, null)]
        ))
      )
    ])
    error_message = "Destination 'name' values must be unique across all destination types in a DCR."
  }

  validation {
    condition     = alltrue([for _, v in var.additional_data_collection_rules : length(v.data_flow) > 0])
    error_message = "Each DCR must define at least one data_flow."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      alltrue([
        for df in v.data_flow: 
        length(setsubtract(
          toset(df.destinations),
          toset(compact(concat(
            [try(v.destinations.azure_monitor_metrics.name, null)],
            [try(v.destinations.event_hub.name, null)],
            [try(v.destinations.event_hub_direct.name, null)],
            [try(v.destinations.log_analytics.name, null)],
            [try(v.destinations.monitor_account.name, null)],
            [try(v.destinations.storage_blob.name, null)],
            [try(v.destinations.storage_blob_direct.name, null)],
            [try(v.destinations.storage_table_direct.name, null)]
          )))
        )) == 0
      ])
    ])
    error_message = "Each data_flow.destinations must reference names defined under 'destinations'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      alltrue([
        for df in v.data_flow: 
        contains(df.destinations, try(v.destinations.azure_monitor_metrics.name, "")) ?
          length(setsubtract(toset(df.streams), toset(["Microsoft-InsightsMetrics"]))) == 0
        :   true
      ])
    ])
    error_message = "When routing to 'azure_monitor_metrics', streams must be only 'Microsoft-InsightsMetrics'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      contains(["linux", "windows", "agentdirecttostore", "workspacetransforms"], lower(v.kind))
    ])
    error_message = "kind must be one of: Linux, Windows, AgentDirectToStore, WorkspaceTransforms."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      lower(v.kind) != "linux" || length(try(v.data_sources.windows_event_log, [])) == 0
    ])
    error_message = "For kind 'Linux', 'windows_event_log' data sources are not allowed."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      lower(v.kind) != "windows" || length(try(v.data_sources.syslog, [])) == 0
    ])
    error_message = "For kind 'Windows', 'syslog' data sources are not allowed."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        !(
          try(v.destinations.event_hub_direct.name, "")     != "" ||
          try(v.destinations.storage_blob_direct.name, "")  != "" ||
          try(v.destinations.storage_table_direct.name, "") != ""
        )
      ) || lower(v.kind) == "agentdirecttostore"
    ])
    error_message = "event_hub_direct, storage_blob_direct and storage_table_direct are only allowed when kind = AgentDirectToStore."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      contains(["systemassigned","userassigned"], lower(v.identity.type))
    ])
    error_message = "identity.type must be 'SystemAssigned' or 'UserAssigned'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        lower(v.identity.type) == "systemassigned" && length(try(v.identity.identity_ids, [])) == 0
      ) || (
        lower(v.identity.type) == "userassigned" && length(try(v.identity.identity_ids, [])) == 1
        && alltrue([for id in try(v.identity.identity_ids, []) : length(trim(id)) > 0])
      )
    ])
    error_message = "For SystemAssigned do not provide identity_ids. For UserAssigned provide exactly one non-empty identity_id."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      (
        try(v.data_sources.data_import, null) == null
        || length(try(v.data_sources.data_import.event_hub_data_sources, [])) > 0
      )
    ])
    error_message = "When 'data_import' is set, it must include at least one 'event_hub_data_source'."
  }

  validation {
    condition = alltrue([
      for _, v in var.additional_data_collection_rules: 
      alltrue([
        for      pc in try(v.data_sources.performance_counter, [])                                : 
        contains(pc.streams, "Microsoft-InsightsMetrics") ? pc.sampling_frequency_in_seconds == 60: true
      ])
    ])
    error_message = "performance_counter using 'Microsoft-InsightsMetrics' must set sampling_frequency_in_seconds = 60."
  }

  description = <<-DOC

  ```
  Additional data collection rules to create.
  {
    name        = Name of the data collection rule.
    kind        = Kind of the data collection rule. Possible values are "Linux" and "Windows". Default is "Linux".
    description = Description of the data collection rule.
    tags        = Tags to assign to the data collection rule.

    destinations = {
      azure_monitor_metrics = {
        name = Name of the Azure Monitor Metrics destination.
      }
      event_hub = {
        name         = Name of the Event Hub destination.
        event_hub_id = Resource ID of the Event Hub namespace.
      }
      event_hub_direct = {
        name         = Name of the Event Hub Direct destination.
        event_hub_id = Resource ID of the Event Hub namespace.
      }
      log_analytics = {
        name                  = Name of the Log Analytics destination.
        workspace_resource_id = Resource ID of the Log Analytics workspace.
      }
      monitor_account = {
        name               = Name of the Monitor Account destination.
        monitor_account_id = Resource ID of the Monitor Account.
      }
      storage_blob = {
        name               = Name of the Storage Blob destination.
        storage_account_id = Resource ID of the Storage Account.
        container_name     = Name of the Blob container.
      }
      storage_blob_direct = {
        name               = Name of the Storage Blob Direct destination.
        storage_account_id = Resource ID of the Storage Account.
        container_name     = Name of the Blob container.
      }
      storage_table_direct = {
        name               = Name of the Storage Table Direct destination.
        storage_account_id = Resource ID of the Storage Account.
        table_name         = Name of the Table.
      }
    }

    data_sources = {
      data_import = {
        event_hub_data_sources = [
          {
            name           = Name of the Event Hub data source.
            stream         = Stream to which data will be sent. E.g. "Microsoft-Event".
            consumer_group = Consumer group for the Event Hub.
          }
        ]
      }

      extension = [
        {
          extension_name = Name of the extension. E.g. "DependencyAgent".
          name           = Name of the data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-ServiceMap"].
        }
      ]

      iis_log = [
        {
          name            = Name of the IIS log data source.
          streams         = List of streams to which data will be sent. E.g. ["Microsoft-IISLog"].
          log_directories = List of directories where IIS logs are located.
        }
      ]
      log_file = [
        {
          name          = Name of the log file data source.
          streams       = List of streams to which data will be sent. E.g. ["Microsoft-WindowsEvent"].
          file_patterns = List of file patterns to include. E.g. ["/var/log/syslog*"].
          format        = Format of the log file. E.g. "Syslog", "JSON", "CEF".
        }
      ]

      performance_counter = [
        {
          name                          = Name of the performance counter data source.
          streams                       = List of streams to which data will be sent. E.g. ["Microsoft-InsightsMetrics"].
          counter_specifiers            = List of performance counter specifiers.
          sampling_frequency_in_seconds = Sampling frequency in seconds.
        }
      ]

      platform_telemetry = [
        {
          name    = Name of the platform telemetry data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-PlatformTelemetry"].
        }
      ]

      prometheus_forwarder = [
        {
          name    = Name of the Prometheus forwarder data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-PrometheusMetrics"].
        }
      ]

      syslog = [
        {
          name           = Name of the syslog data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-Syslog"].
          facility_names = List of facility names to include. E.g. ["auth", "cron"].
          log_levels     = List of log levels to include. E.g. ["emerg", "alert", "crit", "err"].
        }
      ]

      windows_event_log = [
        {
          name           = Name of the Windows event log data source.
          streams        = List of streams to which data will be sent. E.g. ["Microsoft-Event"].
          x_path_queries = List of XPath queries to filter events.
        }
      ]

      windows_firewall_log = [
        {
          name    = Name of the Windows firewall log data source.
          streams = List of streams to which data will be sent. E.g. ["Microsoft-WindowsFirewall"].
        }
      ]
    }

    data_flow = [
      {
        streams      = List of streams to route. E.g. ["Microsoft-Event"].
        destinations = List of destination names to which data will be sent.
      }
    ]

    identity = {
      type         = Type of managed identity. Possible values are "SystemAssigned", "UserAssigned" and "SystemAssigned, UserAssigned".
      identity_ids = List of user assigned identity IDs if type includes "UserAssigned".
    }
  }

  ```
  DOC
}