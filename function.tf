# Deploys an Azure function app where each function
# monitors a service if it is feature-enabled.

# Provides tenant ID
data "azurerm_client_config" "current" {}

data "archive_file" "function_package" {
  count       = local.enable_function_app ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "function_app.zip"

  excludes = local.excluded_functions
}

resource "azurerm_service_plan" "asp_func_app" {
  count               = local.enable_function_app ? 1 : 0
  name                = "asp-monitor-dev-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  #TODO: Is Linux possible? Do we need Premium?
  os_type  = "Windows"
  sku_name = "EP1"
}

resource "azurerm_key_vault" "sql_monitor" {
  count                       = local.enable_function_app && var.functions_config.stage_sql != "off" ? 1 : 0
  name                        = local.sql_key_vault_name
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  # Function App Managed Identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_windows_function_app.func_app[0].identity[0].principal_id

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

  # User running terraform
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

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

resource "azurerm_role_assignment" "blob_contributor" {
  count                = local.enable_function_app ? 1 : 0
  scope                = azurerm_storage_account.sa_func_app[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_windows_function_app.func_app[0].identity[0].principal_id
}

resource "azurerm_storage_account" "sa_func_app" {
  count                    = local.enable_function_app ? 1 : 0
  name                     = format("samonitor01%s", lower(local.customer_code))
  resource_group_name      = var.log_analytics_workspace.resource_group_name
  location                 = var.log_analytics_workspace.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container_func" {
  count                 = local.enable_function_app ? 1 : 0
  name                  = "sc-monitoring-code-01"
  storage_account_name  = azurerm_storage_account.sa_func_app[0].name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "storage_container_state" {
  count                 = local.enable_function_app ? 1 : 0
  name                  = "sc-monitoring-state-01"
  storage_account_name  = azurerm_storage_account.sa_func_app[0].name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "storage_blob_function_code" {
  count                  = local.enable_function_app ? 1 : 0
  name                   = format("function-blob-%s-%s.zip", local.customer_code, data.archive_file.function_package[0].output_md5)
  storage_account_name   = azurerm_storage_account.sa_func_app[0].name
  storage_container_name = azurerm_storage_container.storage_container_func[0].name
  type                   = "Block"
  source                 = data.archive_file.function_package[0].output_path
  content_md5            = data.archive_file.function_package[0].output_md5
}

resource "azurerm_storage_blob" "storage_blob_function_state" {
  for_each               = toset(local.enabled_functions)
  name                   = format("state-blob-%s-%s", each.key, local.customer_code)
  storage_account_name   = azurerm_storage_account.sa_func_app[0].name
  storage_container_name = azurerm_storage_container.storage_container_state[0].name
  type                   = "Block"
  content_type           = "application/json; charset=utf-8"
}

resource "azurerm_windows_function_app" "func_app" {
  count               = local.enable_function_app ? 1 : 0
  name                = format("func-dev-Monitoring-%s-01", local.customer_code)
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location

  storage_account_name       = azurerm_storage_account.sa_func_app[0].name
  storage_account_access_key = azurerm_storage_account.sa_func_app[0].primary_access_key
  service_plan_id            = azurerm_service_plan.asp_func_app[0].id

  site_config {
    application_insights_key               = azurerm_application_insights.appi[0].instrumentation_key
    application_insights_connection_string = azurerm_application_insights.appi[0].connection_string

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(
    {
      WEBSITE_RUN_FROM_PACKAGE       = azurerm_storage_blob.storage_blob_function_code[0].url
      FUNCTIONS_WORKER_RUNTIME       = "powershell"
      APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appi[0].instrumentation_key
      SQL_MONITORING_KEY_VAULT       = var.functions_config.stage_sql == "off" ? "" : local.sql_key_vault_name
      TENANT_ID                      = data.azurerm_client_config.current.tenant_id
      ROOT_MANAGEMENT_GROUP_ID       = var.root_management_group_id
    },
    {
      # For each function, set an environment variable <func>_SERVICE_URI, which is either the prd or the int event pipeline
      for func_key, stage in var.functions_config :
      upper("${replace(func_key, "stage_", "")}_SERVICE_URI") => stage == "prd" ? local.service_uri : local.service_uri_integration
      if stage != "off"
    },
    {
      # For each function, set an environment variable <func>_STATE with the url to the state blob
      for k, v in azurerm_storage_blob.storage_blob_function_state : upper("${k}_STATE") => v.url
    }
  )
}

resource "azurerm_application_insights" "appi" {
  count               = local.enable_function_app ? 1 : 0
  name                = format("appi-Monitoring-dev")
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  application_type    = "web"
}
