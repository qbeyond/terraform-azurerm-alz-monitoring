# Deploys an Azure function app where each function
# monitors a service if it is feature-enabled.

# Provides tenant ID
data "azurerm_client_config" "current" {}

data "archive_file" "function_package" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "function_app.zip"

  excludes = local.excluded_functions
}

resource "azurerm_service_plan" "asp_func_app" {
  name                = "asp-monitor-dev-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  #TODO: Is Linux possible? Do we need Premium?
  os_type             = "Windows"
  sku_name            = "EP1"
}

resource "azurerm_key_vault" "sql_monitor" {
  count                       = var.functions_config.stage_sql == "off" ? 0 : 1
  name                        = local.key_vault_name
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_windows_function_app.func_app.identity[0].principal_id

    key_permissions = [
      "Get", "List",
    ]

    secret_permissions = [
      "Get", "List",
    ]

    storage_permissions = [
      "Get", "List",
    ]
  }
}

resource "azurerm_storage_account" "sa_func_app" {
  name                     = format("sasqlmonitor01%s", lower(local.customer_code))
  resource_group_name      = var.log_analytics_workspace.resource_group_name
  location                 = var.log_analytics_workspace.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container_func" {
  name                  = "sc-monitoring-01"
  storage_account_name  = azurerm_storage_account.sa_func_app.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = format("function-blob-%s-%s.zip", local.customer_code, data.archive_file.function_package.output_md5)
  storage_account_name   = azurerm_storage_account.sa_func_app.name
  storage_container_name = azurerm_storage_container.storage_container_func.name
  type                   = "Block"
  source                 = data.archive_file.function_package.output_path
  content_md5            = data.archive_file.function_package.output_md5
}

resource "azurerm_windows_function_app" "func_app" {
  name                = format("func-dev-Monitoring-%s-01", local.customer_code)
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location

  storage_account_name       = azurerm_storage_account.sa_func_app.name
  storage_account_access_key = azurerm_storage_account.sa_func_app.primary_access_key
  service_plan_id            = azurerm_service_plan.asp_func_app.id

  site_config {
    application_insights_key               = azurerm_application_insights.appi.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.appi.connection_string

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE         = azurerm_storage_blob.storage_blob_function.url
    FUNCTIONS_WORKER_RUNTIME         = "powershell"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appi.instrumentation_key
    SQL_MONITORING_KEY_VAULT         = var.functions_config.stage_sql == "off" ? "" : local.key_vault_name
    TENANT_ID                        = data.azurerm_client_config.current.tenant_id
    ROOT_MANAGEMENT_GROUP_ID         = var.root_management_group_id
  }
}

resource "azurerm_application_insights" "appi" {
  name                = format("appi-Monitoring-dev")
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  application_type    = "web"
}
