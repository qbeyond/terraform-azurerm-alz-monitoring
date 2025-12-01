# ALZ Monitoring

[![GitHub tag](https://img.shields.io/github/v/tag/qbeyond/terraform-azurerm-alz-monitoring.svg)](https://registry.terraform.io/modules/qbeyond/alz-monitoring/azurerm/latest)
[![License](https://img.shields.io/github/license/qbeyond/terraform-azurerm-alz-monitoring.svg)](https://github.com/qbeyond/terraform-azurerm-alz-monitoring/blob/main/LICENSE)

----

This module deploys all resources to enable the monitoring of a Log Analytics Workspace for all managed resources by the managed services provider. This includes Action group to send alerts to event pipeline of MSP, alerts for specific resources and a automation to add information (especially tags) to the LAW.

To enable usage of tags and resource properties in monitoring queries an existing automation account is used to import resource metadata into the central log analytics workspace.

<!-- BEGIN_TF_DOCS -->
## Usage

To use this module a resource group and log analytics workspace is required. 
The webhook URL needs to point to a valid receiver for pipeline events.
If authentication or other options are required they need to be included in the URL as path or query parameters.

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-Monitor-dev-01"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-cust-Management-Monitor-01"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_automation_account" "example" {
  name                = "aac-Management-Monitor-dev-01"
  sku_name            = "Basic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "monitor" {
  source                  = "../.."
  log_analytics_workspace = azurerm_log_analytics_workspace.example

  additional_regions = ["northeurope"]
  event_pipeline_config = {
    enabled                 = true
    name                    = "QBY EventPipeline"
    service_uri             = "https://qbeyond.de/Webhook?code={{secret}}}&clientid=fctkey-cust-prd-eventpipeline-01"
    service_uri_integration = "https://qbeyond.de/WebhookIntegration?code={{secret}}}&clientid=fctkey-cust-int-eventpipeline-01"
  }

  automation_account = azurerm_automation_account.example
  secret             = "impressum"
  secret_integration = "integration"
  tags = {
    "MyTagName" = "MyTagValue"
  }
}
```

### Extra Queries

You can specify additional kusto queries to monitor.
```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-Monitor-dev-01"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-cust-Management-Monitor-01"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_automation_account" "example" {
  name                = "aac-Management-Monitor-dev-01"
  sku_name            = "Basic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "monitor" {
  source                  = "../.."
  log_analytics_workspace = azurerm_log_analytics_workspace.example

  event_pipeline_config = {
    enabled                 = true
    name                    = "QBY EventPipeline"
    service_uri             = "https://qbeyond.de/Webhook?code={{secret}}}&clientid=fctkey-cust-prd-eventpipeline-01"
    service_uri_integration = "https://qbeyond.de/WebhookIntegration?code={{secret}}}&clientid=fctkey-cust-int-eventpipeline-01"
  }
  automation_account = azurerm_automation_account.example
  secret             = "impressum"
  secret_integration = "integration"

  additional_queries = {
    "alr-prd-diskspace-bkp-law-logsea-warn-01" : {
      query_path  = "${path.module}/queries/failed_jobs.kusto"
      description = "Example of monitoring for failed backup jobs"
      time_window = "PT15M"
      frequency   = "PT15M"
      display_name              = "alr-prd-diskspace-bkp-law-logsea-warn-01"
      query_time_range_override = "P2D"
      include_failing_periods = {
        minimum_failing_periods_to_trigger_alert = 1
        number_of_evaluation_periods             = 1
      }
    }
  }
  active_services = {
    active_directory = true
    managed_os       = true
    mssql            = true
  }
}
```
`queries/failed_jobs.kusto`
```kusto
// Example from Azure:
// All Failed Jobs 
// View all failed jobs in the selected time range. 
AddonAzureBackupJobs
| summarize arg_max(TimeGenerated,*) by JobUniqueId
| where JobStatus == "Failed"
```  
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 1.14 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_account"></a> [automation\_account](#input\_automation\_account) | <pre>Automation account where the resource graph script will be deployed.<br/>{<br/>  name                = Name of the automation account.<br/>  id                  = ID of the automation account.<br/>  location            = Location of the automation account.<br/>  resource_group_name = Resource group name of the automation account.<br/>}</pre> | <pre>object({<br/>    name                = string<br/>    id                  = string<br/>    location            = string<br/>    resource_group_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_log_analytics_workspace"></a> [log\_analytics\_workspace](#input\_log\_analytics\_workspace) | <pre>Log Analytics Worksapce that all VMs are connected to for monitoring.<br/>{<br/>  id                  = ID of the Log Analytics Workspace.<br/>  name                = Name of the Log Analytics Workspace.<br/>  resource_group_name = Resource group name of the Log Analytics Workspace.<br/>  location            = Location of the Log Analytics Workspace.<br/>  workspace_id        = Workspace ID of the Log Analytics Workspace.<br/>  primary_shared_key  = Primary shared key of the Log Analytics Workspace.<br/>}</pre> | <pre>object({<br/>    id                  = string<br/>    name                = string<br/>    resource_group_name = string<br/>    location            = string<br/>    workspace_id        = string<br/>    primary_shared_key  = string<br/>  })</pre> | n/a | yes |
| <a name="input_active_services"></a> [active\_services](#input\_active\_services) | <pre>Services to receive event monitoring.<br/>{<br/>  active_directory = Enable monitoring for Azure AD.<br/>  managed_os       = Enable monitoring for Managed OS.<br/>  mssql            = Enable monitoring for Azure SQL and SQL on VMs.<br/>}</pre> | <pre>object({<br/>    active_directory = optional(bool, false)<br/>    managed_os       = optional(bool, false)<br/>    mssql            = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_additional_data_collection_rules"></a> [additional\_data\_collection\_rules](#input\_additional\_data\_collection\_rules) | <pre>Additional data collection rules to create.<br/>{<br/>  name        = Name of the data collection rule.<br/>  kind        = Kind of the data collection rule. Possible values are "Linux" and "Windows". Default is "Linux".<br/>  description = Description of the data collection rule.<br/>  tags        = Tags to assign to the data collection rule.<br/><br/>  destinations = {<br/>    azure_monitor_metrics = {<br/>      name = Name of the Azure Monitor Metrics destination.<br/>    }<br/>    event_hub = {<br/>      name         = Name of the Event Hub destination.<br/>      event_hub_id = Resource ID of the Event Hub namespace.<br/>    }<br/>    event_hub_direct = {<br/>      name         = Name of the Event Hub Direct destination.<br/>      event_hub_id = Resource ID of the Event Hub namespace.<br/>    }<br/>    log_analytics = {<br/>      name                  = Name of the Log Analytics destination.<br/>      workspace_resource_id = Resource ID of the Log Analytics workspace.<br/>    }<br/>    monitor_account = {<br/>      name               = Name of the Monitor Account destination.<br/>      monitor_account_id = Resource ID of the Monitor Account.<br/>    }<br/>    storage_blob = {<br/>      name               = Name of the Storage Blob destination.<br/>      storage_account_id = Resource ID of the Storage Account.<br/>      container_name     = Name of the Blob container.<br/>    }<br/>    storage_blob_direct = {<br/>      name               = Name of the Storage Blob Direct destination.<br/>      storage_account_id = Resource ID of the Storage Account.<br/>      container_name     = Name of the Blob container.<br/>    }<br/>    storage_table_direct = {<br/>      name               = Name of the Storage Table Direct destination.<br/>      storage_account_id = Resource ID of the Storage Account.<br/>      table_name         = Name of the Table.<br/>    }<br/>  }<br/><br/>  data_sources = {<br/>    data_import = {<br/>      event_hub_data_sources = [<br/>        {<br/>          name           = Name of the Event Hub data source.<br/>          stream         = Stream to which data will be sent. E.g. "Microsoft-Event".<br/>          consumer_group = Consumer group for the Event Hub.<br/>        }<br/>      ]<br/>    }<br/><br/>    extension = [<br/>      {<br/>        extension_name = Name of the extension. E.g. "DependencyAgent".<br/>        name           = Name of the data source.<br/>        streams        = List of streams to which data will be sent. E.g. ["Microsoft-ServiceMap"].<br/>      }<br/>    ]<br/><br/>    iis_log = [<br/>      {<br/>        name            = Name of the IIS log data source.<br/>        streams         = List of streams to which data will be sent. E.g. ["Microsoft-IISLog"].<br/>        log_directories = List of directories where IIS logs are located.<br/>      }<br/>    ]<br/>    log_file = [<br/>      {<br/>        name          = Name of the log file data source.<br/>        streams       = List of streams to which data will be sent. E.g. ["Microsoft-WindowsEvent"].<br/>        file_patterns = List of file patterns to include. E.g. ["/var/log/syslog*"].<br/>        format        = Format of the log file. E.g. "Syslog", "JSON", "CEF".<br/>      }<br/>    ]<br/><br/>    performance_counter = [<br/>      {<br/>        name                          = Name of the performance counter data source.<br/>        streams                       = List of streams to which data will be sent. E.g. ["Microsoft-InsightsMetrics"].<br/>        counter_specifiers            = List of performance counter specifiers.<br/>        sampling_frequency_in_seconds = Sampling frequency in seconds.<br/>      }<br/>    ]<br/><br/>    platform_telemetry = [<br/>      {<br/>        name    = Name of the platform telemetry data source.<br/>        streams = List of streams to which data will be sent. E.g. ["Microsoft-PlatformTelemetry"].<br/>      }<br/>    ]<br/><br/>    prometheus_forwarder = [<br/>      {<br/>        name    = Name of the Prometheus forwarder data source.<br/>        streams = List of streams to which data will be sent. E.g. ["Microsoft-PrometheusMetrics"].<br/>      }<br/>    ]<br/><br/>    syslog = [<br/>      {<br/>        name           = Name of the syslog data source.<br/>        streams        = List of streams to which data will be sent. E.g. ["Microsoft-Syslog"].<br/>        facility_names = List of facility names to include. E.g. ["auth", "cron"].<br/>        log_levels     = List of log levels to include. E.g. ["emerg", "alert", "crit", "err"].<br/>      }<br/>    ]<br/><br/>    windows_event_log = [<br/>      {<br/>        name           = Name of the Windows event log data source.<br/>        streams        = List of streams to which data will be sent. E.g. ["Microsoft-Event"].<br/>        x_path_queries = List of XPath queries to filter events.<br/>      }<br/>    ]<br/><br/>    windows_firewall_log = [<br/>      {<br/>        name    = Name of the Windows firewall log data source.<br/>        streams = List of streams to which data will be sent. E.g. ["Microsoft-WindowsFirewall"].<br/>      }<br/>    ]<br/>  }<br/><br/>  data_flow = [<br/>    {<br/>      streams      = List of streams to route. E.g. ["Microsoft-Event"].<br/>      destinations = List of destination names to which data will be sent.<br/>      built_in_transform = Built-in transform to apply to the input stream.<br/>      transform_kql = KQL query that transform the input stream. Used instead of "built_in_transform"<br/>      output_stream = Name of the output stream after the transform.<br/>    }<br/>  ]<br/><br/>  identity = {<br/>    type         = Type of managed identity. Possible values are "SystemAssigned", "UserAssigned" and "SystemAssigned, UserAssigned".<br/>    identity_ids = List of user assigned identity IDs if type includes "UserAssigned".<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name        = string<br/>    kind        = optional(string)<br/>    description = optional(string)<br/>    tags        = optional(map(string), {})<br/><br/>    destinations = object({<br/>      azure_monitor_metrics = optional(object({ name = string }), null)<br/>      event_hub             = optional(object({ name = string, event_hub_id = string }), null)<br/>      event_hub_direct      = optional(object({ name = string, event_hub_id = string }), null)<br/>      log_analytics         = optional(object({ name = string, workspace_resource_id = string }), null)<br/>      monitor_account       = optional(object({ name = string, monitor_account_id = string }), null)<br/>      storage_blob          = optional(object({ name = string, storage_account_id = string, container_name = string }), null)<br/>      storage_blob_direct   = optional(object({ name = string, storage_account_id = string, container_name = string }), null)<br/>      storage_table_direct  = optional(object({ name = string, storage_account_id = string, table_name = string }), null)<br/>    })<br/><br/>    data_sources = optional(object({<br/>      data_import = optional(object({<br/>        event_hub_data_sources = object({<br/>          name           = string<br/>          stream         = string<br/>          consumer_group = optional(string)<br/>        })<br/>      }), null)<br/><br/>      extension = optional(list(object({<br/>        extension_name     = string<br/>        name               = string<br/>        streams            = list(string)<br/>        extension_json     = optional(string)<br/>        input_data_sources = optional(list(string))<br/>      })), [])<br/><br/>      iis_log = optional(list(object({<br/>        name            = string<br/>        streams         = list(string)<br/>        log_directories = optional(list(string))<br/>      })), [])<br/><br/>      log_file = optional(list(object({<br/>        name          = string<br/>        streams       = list(string)<br/>        file_patterns = list(string)<br/>        format        = string<br/>      })), [])<br/><br/>      performance_counter = optional(list(object({<br/>        name                          = string<br/>        streams                       = list(string)<br/>        counter_specifiers            = list(string)<br/>        sampling_frequency_in_seconds = number<br/>      })), [])<br/><br/>      platform_telemetry = optional(list(object({<br/>        name    = string<br/>        streams = list(string)<br/>      })), [])<br/><br/>      prometheus_forwarder = optional(list(object({<br/>        name    = string<br/>        streams = list(string)<br/>      })), [])<br/><br/>      syslog = optional(list(object({<br/>        name           = string<br/>        streams        = list(string)<br/>        facility_names = list(string)<br/>        log_levels     = list(string)<br/>      })), [])<br/><br/>      windows_event_log = optional(list(object({<br/>        name           = string<br/>        streams        = list(string)<br/>        x_path_queries = list(string)<br/>      })), [])<br/><br/>      windows_firewall_log = optional(list(object({<br/>        name    = string<br/>        streams = list(string)<br/>      })), [])<br/>    }), {})<br/><br/>    data_flow = list(object({<br/>      streams            = list(string)<br/>      destinations       = list(string)<br/>      output_stream      = optional(string)<br/>      built_in_transform = optional(string)<br/>      transform_kql      = optional(string)<br/>    }))<br/><br/>    identity = optional(object({<br/>      type         = string<br/>      identity_ids = optional(list(string), [])<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_additional_queries"></a> [additional\_queries](#input\_additional\_queries) | <pre>List of additional alert rule queries to create with a file path, description and time_window.<br/>{<br/>  "query_path"                = Path to the kusto query file.<br/>  "description"               = Description of the alert rule.<br/>  "time_window"               = Time window for the alert rule,                       e.g. "PT5M", "P1D",             "P2D".<br/>  "frequency"                 = Frequency of evaluation,                              e.g. "PT5M", "PT15M".<br/>  "non_productive"            = If true,                                              the alert will use the non productive action group.<br/>  "display_name"              = Optional display name for the alert rule. If not set, the resource name will be used.<br/>  "query_time_range_override" = Optional time range override for the query,           e.g. "P1D",  "P2D". If not set, the time_window will be used.<br/>  "include_failing_periods"   = Optional object to include failing periods in the alert rule.<br/>    {<br/>      minimum_failing_periods_to_trigger_alert = number of failing periods to trigger the alert.<br/>      number_of_evaluation_periods             = number of evaluation periods to consider.<br/>    }<br/>}</pre> | <pre>map(object({<br/>    query_path                = string<br/>    description               = string<br/>    time_window               = string<br/>    frequency                 = string<br/>    non_productive            = optional(bool, false)<br/>    display_name              = optional(string)<br/>    query_time_range_override = optional(string)<br/>    include_failing_periods   = optional(object({<br/>      minimum_failing_periods_to_trigger_alert = number<br/>      number_of_evaluation_periods             = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_additional_regions"></a> [additional\_regions](#input\_additional\_regions) | Regions for additional data collection endpoints outside of the LAWs region. | `set(string)` | `[]` | no |
| <a name="input_customer_code"></a> [customer\_code](#input\_customer\_code) | Customer code used as an identifier in monitoring alerts. Must be specified when no service URI with customer code is given. | `string` | `""` | no |
| <a name="input_event_pipeline_config"></a> [event\_pipeline\_config](#input\_event\_pipeline\_config) | <pre>{<br/>  enabled     = Enable the action group if you want to send data to a monitoring service.<br/>  name        = Name of the alert webhook.<br/>  service_uri = Link to the webhook receiver URL. Must contain the placeholder \"{{secret}}\". This placeholder will be replaced by the secret value from var.secret. This is used to add authentication to the webhook URL as a query parameter.<br/>  service_uri_integration = Same as service_uri for non productive monitoring alerts, the secret value from var.secret_integration will be used here.<br/>}</pre> | <pre>object({<br/>    enabled                 = bool<br/>    name                    = optional(string, "QBY EventPipeline")<br/>    service_uri             = optional(string, "")<br/>    service_uri_integration = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_root_management_group_id"></a> [root\_management\_group\_id](#input\_root\_management\_group\_id) | The management group that will be scanned by the Import-ResourceGraphToLogAnalytics runbook. | `string` | `"alz"` | no |
| <a name="input_secret"></a> [secret](#input\_secret) | Value that will replace the placeholder `{{secret}}` in `event_pipeline_config.service_uri`. | `string` | `""` | no |
| <a name="input_secret_integration"></a> [secret\_integration](#input\_secret\_integration) | Value that will replace the placeholder `{{secret}}` in `event_pipeline_config.service_uri_integration`. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be assigned to all resources. | `map(string)` | `{}` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_endpoint"></a> [access\_endpoint](#output\_access\_endpoint) | The access endpoint of the Logic App workflow. |
| <a name="output_action_group_id"></a> [action\_group\_id](#output\_action\_group\_id) | The id of the action group created for the event pipeline. |
| <a name="output_linux_dcr_ids"></a> [linux\_dcr\_ids](#output\_linux\_dcr\_ids) | Map of DCRs and their resource IDs that should be associated to linux VMs. |
| <a name="output_vminsights_dcr_id"></a> [vminsights\_dcr\_id](#output\_vminsights\_dcr\_id) | Resource ID of the VM-Insights DCR that should be associated with every VM. |
| <a name="output_windows_dcr_ids"></a> [windows\_dcr\_ids](#output\_windows\_dcr\_ids) | Map of DCRs and their resource IDs that should be associated to windows VMs. |
## Resource types

      | Type | Used |
      |------|-------|
        | [azapi_resource](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | 3 |
        | [azurerm_automation_job_schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | 1 |
        | [azurerm_automation_module](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | 2 |
        | [azurerm_automation_runbook](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | 1 |
        | [azurerm_automation_schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | 1 |
        | [azurerm_automation_variable_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | 1 |
        | [azurerm_monitor_action_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | 3 |
        | [azurerm_monitor_data_collection_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_endpoint) | 2 |
        | [azurerm_monitor_data_collection_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | 6 |
        | [azurerm_monitor_scheduled_query_rules_alert_v2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | 1 |
        | [azurerm_resource_group_template_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) | 1 |
        | [time_static](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | 1 |

      **`Used` only includes resource blocks.** `for_each` and `count` meta arguments, as well as resource blocks of modules are not considered.
    
## Modules

No modules.

        ## Resources by Files

            ### custom_logs.tf

            | Name | Type |
            |------|------|
                  | [azapi_resource.data_collection_json_logs_table](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
                  | [azapi_resource.data_collection_text_logs_table](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
                  | [azapi_resource.dcr_custom_json_logs](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
                  | [azurerm_monitor_data_collection_rule.dcr_custom_text_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |

            ### data_collection_rules.tf

            | Name | Type |
            |------|------|
                  | [azurerm_monitor_data_collection_rule.additional_data_collection_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
                  | [azurerm_monitor_data_collection_rule.event_log](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
                  | [azurerm_monitor_data_collection_rule.syslog](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
                  | [azurerm_monitor_data_collection_rule.syslog_notice](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
                  | [azurerm_monitor_data_collection_rule.vm_insight](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |

            ### eventparser.tf

            | Name | Type |
            |------|------|
                  | [azurerm_resource_group_template_deployment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) | resource |

            ### main.tf

            | Name | Type |
            |------|------|
                  | [azurerm_monitor_action_group.eventparser](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
                  | [azurerm_monitor_action_group.eventpipeline](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
                  | [azurerm_monitor_action_group.optional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
                  | [azurerm_monitor_data_collection_endpoint.additional_dces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_endpoint) | resource |
                  | [azurerm_monitor_data_collection_endpoint.dce](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_endpoint) | resource |
                  | [azurerm_monitor_scheduled_query_rules_alert_v2.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
                  | [azurerm_logic_app_workflow.eventparser](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/logic_app_workflow) | data source |
                  | [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

            ### resourcegraph.tf

            | Name | Type |
            |------|------|
                  | [azurerm_automation_job_schedule.resourcegraph_query](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
                  | [azurerm_automation_module.az_accounts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | resource |
                  | [azurerm_automation_module.az_resourcegraph](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | resource |
                  | [azurerm_automation_runbook.resourcegraph_query](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
                  | [azurerm_automation_schedule.twice_daily](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
                  | [azurerm_automation_variable_string.law_sharedkey](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |
                  | [time_static.automation_schedule_tomorrow_5am](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
    
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).

### Tests

To test this module all examples should be applied. This can be done by running `terraform test`.
