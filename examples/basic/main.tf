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
  source              = "../.."
  location            = "westeurope"
  law_id              = azurerm_log_analytics_workspace.example.id
  webhook_name        = "QBY EventPipeline"
  webhook_service_uri = "https://function-app.azurewebsites.net/api/Webhook"
}