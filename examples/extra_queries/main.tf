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
      severity    = 2
      enabled     = false
      skip_query_validation = false
      target_resource_types = [
        "Microsoft.Storage/storageAccounts",
      ]
      display_name              = "alr-prd-diskspace-bkp-law-logsea-warn-01"
      query_time_range_override = "P2D"
      include_failing_periods = {
        minimum_failing_periods_to_trigger_alert = 1
        number_of_evaluation_periods             = 1
      }
    }
    "alr-prd-CustLogText-winux-law-logsea-warn-01" : {
      enabled     = false
      display_name = "Test"
    }
  }
  
  active_services = {
    active_directory = true
    managed_os       = true
    mssql            = true
  }
}
