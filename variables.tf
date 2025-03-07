variable "log_analytics_workspace" {
  type = object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
    primary_shared_key  = string
  })
  description = "Log Analytics Worksapce that all VMs are connected to for monitoring."
  nullable    = false
}

variable "additional_queries" {
  type = map(object({
    query_path     = string
    description    = string
    time_window    = string
    frequency      = string
    non_productive = optional(bool, false)
  }))
  description = "List of additional alert rule queries to create with a file path, description and time_window."
  default     = {}
  nullable    = false
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
  description = "Automation account where the resource graph script will be deployed."
  nullable    = false
}

variable "event_pipeline_config" {
  type = object({
    enabled                 = bool
    name                    = optional(string, "QBY EventPipeline")
    service_uri             = optional(string)
    service_uri_integration = optional(string)
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
  description = "Services to receive event monitoring."
  type = object({
    active_directory = optional(bool, false)
    managed_os       = optional(bool, false)
    mssql            = optional(bool, false)
  })
  default = {}
}

variable "functions_config" {
  type = object({
    subnet_id = optional(string, null)
    stages = object({
      mssql = optional(string, "off")
    })
  })
  description = <<-DOC
  ```
  {
    subnet_id = The id of the subnet that the Monitoring Function App should be connected to.
    stages = A configuration object for each function. Set their stages to either "prd", "int" or "off" {
      mssql = This function monitors MSSQL databases managed by q.beyond
    }
  }
  ```
  DOC

  default = { stages = {} }

  validation {
    condition = alltrue([
      for v in values(var.functions_config.stages) : v == "prd" || v == "int" || v == "off"
    ])
    error_message = "Each function stage value must be one of 'prd', 'int', or 'off'."
  }

  validation {
    condition = (var.functions_config.subnet_id == null || can(regex(
      "^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-_]+/subnets/[a-zA-Z0-9-_]+$",
      var.functions_config.subnet_id
    )))
    error_message = "The subnet_id must be either null or a valid Azure subnet resource ID."
  }
}
