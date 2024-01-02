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
    query_path  = string
    description = string
    time_window = number
  }))
  description = "List of additional alert rule queries to create with a file path, description and time_window."
  default     = {}
  nullable    = false
}

variable "event_pipeline_key" {
  type        = string
  description = "Function key provided by monitoring team."
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
    enabled     = bool
    name        = optional(string, "QBY EventPipeline")
    service_uri = optional(string)
  })

  description = <<-DOC
  ```
  {
    enabled       = Enable the action group if you want to send data to a monitoring service.
    name          = Name of the alert webhook.
    service_uri   = Link to the webhook receiver URL. Must contain the placeholder \"{{secret}}\". This placeholder will be replaced by the secret value from var.event_pipeline_key. This is used to add authentication to the webhook URL as a query parameter.
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
