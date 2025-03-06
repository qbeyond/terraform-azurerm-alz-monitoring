provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-Monitor-dev-01"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-cust2-Management-Monitor-01"
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

resource "azurerm_resource_group" "test_sql" {
  name     = "rg-sql-monitoring-dev-01"
  location = "northeurope"
}

resource "azurerm_virtual_network" "test_vnet" {
  name                = "vnet-10-0-0-0-16-northeurope"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test_sql.location
  resource_group_name = azurerm_resource_group.test_sql.name
}

resource "azurerm_subnet" "test_subnet" {
  name                 = "snet-10-0-1-0-24-sql-monitoring"
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  resource_group_name  = azurerm_resource_group.test_sql.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_endpoint" "private_endpoint_funcapp" {
  name                = format("pe-10-0-1-0-24-sql-monitoring-%s", module.monitor.function_app.name)
  location            = azurerm_resource_group.test_sql.location
  resource_group_name = azurerm_resource_group.test_sql.name
  subnet_id           = azurerm_subnet.test_subnet.id

  private_service_connection {
    name                           = format("psc-sql-monitoring-%s", module.monitor.function_app.name)
    private_connection_resource_id = module.monitor.function_app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_mssql_server" "example" {
  name                         = "sql-cust2-dev-monitor-01"
  resource_group_name          = azurerm_resource_group.test_sql.name
  location                     = azurerm_resource_group.test_sql.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "H@Sh1CoR3!"
}

resource "azurerm_mssql_database" "example" {
  name      = "sqldb-dev-Monitor-01"
  server_id = azurerm_mssql_server.example.id
}

resource "azurerm_private_endpoint" "private_endpoint_sql" {
  name                = "pe-10-0-1-0-24-sql-monitoring-sql-cust2-dev-Monitor-01"
  resource_group_name = azurerm_resource_group.test_sql.name
  location            = azurerm_resource_group.test_sql.location
  subnet_id           = azurerm_subnet.test_subnet.id

  private_service_connection {
    name                           = "privateserviceconnection-sql"
    private_connection_resource_id = azurerm_mssql_server.example.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

module "monitor" {
  source                  = "../.."
  log_analytics_workspace = azurerm_log_analytics_workspace.example

  additional_regions = ["northeurope"]
  event_pipeline_config = {
    enabled                 = true
    name                    = "QBY EventPipeline"
    service_uri             = "https://qbeyond.de/Webhook?code={{secret}}}&clientid=fctkey-cust-prd-eventpipeline-01"
    service_uri_integration = "https://qbeyond.de/WebhookIntegration?code={{secret}}}&clientid=fctkey-cust2-int-eventpipeline-01"
  }

  automation_account = azurerm_automation_account.example
  secret             = "impressum"
  secret_integration = "integration"
  tags = {
    "MyTagName" = "MyTagValue"
  }

  # TODO: Add code to test monitoring function app
}
