# VM Monitoring
[![GitHub tag](https://img.shields.io/github/v/tag/qbeyond/terraform-azurerm-vm-monitoring.svg)](https://registry.terraform.io/modules/qbeyond/vm-monitoring/azurerm/latest)
[![License](https://img.shields.io/github/license/qbeyond/terraform-azurerm-vm-monitoring.svg)](https://github.com/qbeyond/terraform-azurerm-vm-monitoring/blob/main/LICENSE)

----

This is a module for creating monitoring rules on top of a central log analytics workspace. the query rules and output are compatible with the event pipeline for central monitoring of q.beyond AG.

WARNING: This module will not work on previously soft deleted LAWs. Either choose a new name or wait for soft deleteion to expire.

<!-- BEGIN_TF_DOCS -->
## Usage

To use this module a resource group and log analytics workspace is required.
The webhook URL needs to point to a valid receiver for pipeline events.
If authentication or other options are required they need to be included in the URL as path or query parameters.

Optionally you can specify additional kusto queries to monitor. See `examples/extra_queries/main.tf` for details.

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

module "monitor" {
  source                  = "../.."
  log_analytics_workspace = {
    id                  = azurerm_log_analytics_workspace.example.id
    name                = azurerm_log_analytics_workspace.example.name
    resource_group_name = azurerm_log_analytics_workspace.example.resource_group_name
    location            = azurerm_log_analytics_workspace.example.location
  }
  webhook_name            = "QBY EventPipeline"
  webhook_service_uri     = "https://function-app.azurewebsites.net/api/Webhook"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_log_analytics_workspace"></a> [log\_analytics\_workspace](#input\_log\_analytics\_workspace) | Log Analytics Worksapce that all VMs are connected to for monitoring | <pre>object({<br>    id                  = string<br>    name                = string<br>    resource_group_name = string<br>    location            = string<br>  })</pre> | n/a | yes |
| <a name="input_webhook_name"></a> [webhook\_name](#input\_webhook\_name) | Name of the alert webhook | `string` | n/a | yes |
| <a name="input_webhook_service_uri"></a> [webhook\_service\_uri](#input\_webhook\_service\_uri) | Link to the webhook receiver URL | `string` | n/a | yes |
| <a name="input_additional_queries"></a> [additional\_queries](#input\_additional\_queries) | List of additional alert rule queries to create with a file path, description and time\_window | <pre>map(object({<br>    query_path  = string<br>    description = string<br>    time_window = number<br>  }))</pre> | `{}` | no |
## Outputs

No outputs.

## Resource types

| Type | Used |
|------|-------|
| [azurerm_log_analytics_datasource_windows_event](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_datasource_windows_event) | 2 |
| [azurerm_monitor_action_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | 1 |
| [azurerm_monitor_scheduled_query_rules_alert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert) | 1 |

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
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).