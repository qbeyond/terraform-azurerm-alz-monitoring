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
    "time_window"               = Time window for the alert rule,                       e.g. "PT5M", "P1D", "P2D".
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
    enabled       = Enable the action group if you want to send data to a monitoring service.
    name          = Name of the alert webhook.
    service_uri   = Link to the webhook receiver URL. Must contain the placeholder \"{{secret}}\". This placeholder will be replaced by the secret value from var.secret. This is used to add authentication to the webhook URL as a query parameter.
    service_uri_integration   = Same as service_uri for non productive monitoring alerts, the secret value from var.secret_integration will be used here.
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
  default = {}
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