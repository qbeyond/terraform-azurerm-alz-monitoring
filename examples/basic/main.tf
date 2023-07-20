provider "azurerm" {
  features{}
  skip_provider_registration = true
}

data "azurerm_subscription" "current" {
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
  name = "aac-Management-Monitor-dev-01"
  sku_name = "Basic"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "monitor" {
  source                  = "../.."
  log_analytics_workspace = azurerm_log_analytics_workspace.example
  webhook_name            = "QBY EventPipeline"
  webhook_service_uri     = "https://function-app.azurewebsites.net/api/Webhook"
  resource_group          = azurerm_resource_group.example
  automation_account      = azurerm_automation_account.example
  subscription_id            = data.azurerm_subscription.current.id
  event_pipeline_key      = "key"
  }
