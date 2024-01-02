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
    service_uri = "https://my-webhook.azurewebsites.net/api/GenericWebhookJS1?code={{pipeline_key}}&clientid=some-fct-key"
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
