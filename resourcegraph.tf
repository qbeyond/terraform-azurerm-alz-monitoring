resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name

  module_link {
    uri = "https://devopsgallerystorage.blob.core.windows.net:443/packages/az.accounts.2.12.1.nupkg"
  }
}

resource "azurerm_automation_module" "az_resourcegraph" {
  name                    = "Az.Resourcegraph"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  module_link {
    uri = "https://devopsgallerystorage.blob.core.windows.net:443/packages/az.resourcegraph.0.13.0.nupkg"
  }
  depends_on = [azurerm_automation_module.az_accounts]
}

resource "azurerm_automation_runbook" "resourcegraph_query" {
  name                    = "Import-ResourceGraphToLogAnalytics"
  location                = var.automation_account.location
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This runbook imports results from defined azure resource graph query to log analytics workspace."
  runbook_type            = "PowerShell"
  content                 = file("${path.module}/resourcegraph/Import-ResourceGraphToLogAnalytics.ps1")
}

resource "azurerm_automation_variable_string" "law_sharedkey" {
  name                    = "law_sharedkey"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  value                   = var.primary_shared_key
  encrypted               = true
}

resource "azurerm_automation_variable_string" "default_subscription" {
  name                    = "default_subscription"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  value                   = data.azurerm_subscription.current.subscription_id
}

resource "time_static" "automation_schedule_tomorrow_5am" {
  rfc3339 = timeadd(formatdate("YYYY-MM-DD'T'05:00:00Z", timestamp()), "24h")
  triggers = {
    aac_name  = var.automation_account.name
    aac_id    = var.automation_account.id
    rg_name   = var.automation_account.resource_group_name
    rg_id     = var.resource_group.id
    frequency = "Day"
    interval  = 1
    timezone  = "Europe/Berlin"
  }
}

resource "azurerm_automation_schedule" "daily" {
  name                    = "aas-Import-ResourceGraphToLogAnalytics-Once-Daily"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  frequency               = time_static.automation_schedule_tomorrow_5am.triggers.frequency
  interval                = time_static.automation_schedule_tomorrow_5am.triggers.interval
  timezone                = time_static.automation_schedule_tomorrow_5am.triggers.timezone
  start_time              = time_static.automation_schedule_tomorrow_5am.rfc3339
}

resource "azurerm_automation_job_schedule" "resourcegraph_query" {
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  schedule_name           = azurerm_automation_schedule.daily.name
  runbook_name            = azurerm_automation_runbook.resourcegraph_query.name

  parameters = {
    query                    = file("${path.module}/resourcegraph/resource.kusto")
    managementgroupidtocheck = "alz"
    logtype                  = "MonitoringResources"
    customerid               = var.log_analytics_workspace.workspace_id
  }
}

