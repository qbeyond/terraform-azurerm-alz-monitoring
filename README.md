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
  event_pipeline_config   = {
    enabled = true
    name = "QBY EventPipeline"
    service_uri = "https://my-webhook.azurewebsites.net/api/GenericWebhookJS1?code={{secret}}&clientid=some-fct-key"
  }
  automation_account      = azurerm_automation_account.example
  event_pipeline_key      = "key"
}
```

### Extra Queries

You can specify additional kusto queries to monitor.
```hcl
provider "azurerm" {
  features{}
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
  event_pipeline_config   = {
    enabled = true
    name = "QBY EventPipeline"
    service_uri = "https://my-webhook.azurewebsites.net/api/GenericWebhookJS1?code={{secret}}&clientid=some-fct-key"
  }
  automation_account      = azurerm_automation_account.example
  event_pipeline_key      = "key"

  additional_queries    = {
    "alr-prd-diskspace-bkp-law-logsea-warn-01": {
        query_path  = "${path.module}/queries/failed_jobs.kusto"
        description = "Example of monitoring for failed backup jobs"
        time_window = 2280
    }
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_account"></a> [automation\_account](#input\_automation\_account) | Automation account where the resource graph script will be deployed. | <pre>object({<br>    name                = string<br>    id                  = string<br>    location            = string<br>    resource_group_name = string<br>  })</pre> | n/a | yes |
| <a name="input_log_analytics_workspace"></a> [log\_analytics\_workspace](#input\_log\_analytics\_workspace) | Log Analytics Worksapce that all VMs are connected to for monitoring. | <pre>object({<br>    id                  = string<br>    name                = string<br>    resource_group_name = string<br>    location            = string<br>    workspace_id        = string<br>    primary_shared_key  = string<br>  })</pre> | n/a | yes |
| <a name="input_additional_queries"></a> [additional\_queries](#input\_additional\_queries) | List of additional alert rule queries to create with a file path, description and time\_window. | <pre>map(object({<br>    query_path  = string<br>    description = string<br>    time_window = number<br>  }))</pre> | `{}` | no |
| <a name="input_event_pipeline_config"></a> [event\_pipeline\_config](#input\_event\_pipeline\_config) | <pre>{<br>    enabled       = Enable the action group if you want to send data to a monitoring service.<br>    name          = Name of the alert webhook.<br>    service_uri   = Link to the webhook receiver URL. Must contain the placeholder \"{{secret}}\". This placeholder will be replaced by the secret value from var.event_pipeline_key. This is used to add authentication to the webhook URL as a query parameter.<br>}</pre> | <pre>object({<br>    enabled     = bool<br>    name        = optional(string)<br>    service_uri = optional(string)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_event_pipeline_key"></a> [event\_pipeline\_key](#input\_event\_pipeline\_key) | Function key provided by monitoring team. | `string` | `""` | no |
## Outputs

No outputs.

## Resource types

| Type | Used |
|------|-------|
| [azurerm_automation_job_schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | 1 |
| [azurerm_automation_module](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | 2 |
| [azurerm_automation_runbook](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | 1 |
| [azurerm_automation_schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | 1 |
| [azurerm_automation_variable_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | 1 |
| [azurerm_log_analytics_datasource_windows_event](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_datasource_windows_event) | 2 |
| [azurerm_monitor_action_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | 1 |
| [azurerm_monitor_scheduled_query_rules_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert) | 1 |
| [time_static](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | 1 |

**`Used` only includes resource blocks.** `for_each` and `count` meta arguments, as well as resource blocks of modules are not considered.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vm_insights"></a> [vm\_insights](#module\_vm\_insights) | qbeyond/log-analytics-VMInsights/azurerm | 1.0.2 |

## Resources by Files

### main.tf

| Name | Type |
|------|------|
| [azurerm_log_analytics_datasource_windows_event.application](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_datasource_windows_event) | resource |
| [azurerm_log_analytics_datasource_windows_event.system](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_datasource_windows_event) | resource |
| [azurerm_monitor_action_group.eventpipeline](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_scheduled_query_rules_alert.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

### resourcegraph.tf

| Name | Type |
|------|------|
| [azurerm_automation_job_schedule.resourcegraph_query](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_module.az_accounts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | resource |
| [azurerm_automation_module.az_resourcegraph](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | resource |
| [azurerm_automation_runbook.resourcegraph_query](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
| [azurerm_automation_schedule.daily](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_automation_variable_string.law_sharedkey](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string) | resource |
| [time_static.automation_schedule_tomorrow_5am](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).