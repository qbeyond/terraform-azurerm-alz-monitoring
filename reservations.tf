resource "azurerm_automation_module" "az_reservations" {
  count                   = var.reservations.enabled ? 1 : 0
  name                    = "Az.Reservations"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name

  module_link {
    uri = "https://cdn.powershellgallery.com/packages/az.reservations.0.14.1.nupkg"
  }
}

resource "azurerm_automation_runbook" "reservation_to_law" {
  count                   = var.reservations.enabled ? 1 : 0
  name                    = "Import-ReservationsToLogAnalytics"
  location                = var.automation_account.location
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This runbook imports reservations in the tenant to the log analytics workspace"
  runbook_type            = "PowerShell"
  content                 = file("${path.module}/runbooks/Import-ReservationsToLogAnalytics.ps1")
}

resource "time_static" "monthly_start" {
  count   = var.reservations.enabled ? 1 : 0
  rfc3339 = timeadd(timestamp(), "24h")
}

resource "azurerm_automation_schedule" "once_monthly" {
  count                   = var.reservations.enabled ? 1 : 0
  name                    = "aas-Import-ReservationsToLogAnalytics-Once-Monthly"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name

  frequency  = "Month"
  interval   = 1
  month_days = [1]

  start_time = time_static.monthly_start[0].rfc3339
}

resource "azurerm_automation_job_schedule" "reservation_to_law" {
  count                   = var.reservations.enabled ? 1 : 0
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  schedule_name           = azurerm_automation_schedule.once_monthly[0].name
  runbook_name            = azurerm_automation_runbook.reservation_to_law[0].name

  parameters = {
    customerid = var.log_analytics_workspace.workspace_id
  }

  lifecycle {
    replace_triggered_by = [azurerm_automation_runbook.reservation_to_law[0]]
  }
}
