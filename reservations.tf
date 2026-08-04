resource "azurerm_automation_module" "az_reservations" {
  count                   = var.reservations.enabled ? 1 : 0
  name                    = "Az.Reservations"
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name

  module_link {
    uri = "https://cdn.powershellgallery.com/packages/az.reservations.0.14.1.nupkg"
  }
}

resource "azurerm_automation_runbook" "reservations_to_law" {
  count                   = var.reservations.enabled ? 1 : 0
  name                    = "Import-ReservationsToLogAnalytics"
  location                = var.automation_account.location
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  log_verbose             = true
  log_progress            = true
  description             = "This runbook imports reservations in the tenant to the log analytics workspace"
  runbook_type            = "PowerShell"
  content                 = file("${path.module}/runbooks/Import-ReservationsToLogAnalytics.ps1")

  depends_on = [
    azurerm_automation_module.az_reservations
  ]
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

resource "azurerm_automation_job_schedule" "reservations_to_law" {
  count                   = var.reservations.enabled ? 1 : 0
  resource_group_name     = var.automation_account.resource_group_name
  automation_account_name = var.automation_account.name
  schedule_name           = azurerm_automation_schedule.once_monthly[0].name
  runbook_name            = azurerm_automation_runbook.reservations_to_law[0].name

  parameters = {
    customerid = var.log_analytics_workspace.workspace_id
  }

  lifecycle {
    replace_triggered_by = [azurerm_automation_runbook.reservations_to_law[0]]
  }
}

resource "azurerm_monitor_action_group" "reservationexpiry" {
  count               = var.reservations.enabled ? 1 : 0
  name                = "ag-${local.customer_code}-prd-reservationexpiry"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "reservations"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.reservations.emails
    content {
      name          = "Reservations are about to expire"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "reservationexpiry" {
  count               = var.reservations.enabled ? 1 : 0
  name                = "alr-prd-ReservationExpiry-res-law-logsea-warn-01"
  location            = var.log_analytics_workspace.location
  resource_group_name = var.log_analytics_workspace.resource_group_name
  tags                = var.tags

  scopes      = [var.log_analytics_workspace.id]
  description = "Retrieves reservations in the tenant that are about to expire"
  enabled     = true
  severity    = 2

  evaluation_frequency = "P1D"
  window_duration      = "P2D"

  action {
    action_groups = [azurerm_monitor_action_group.reservationexpiry[0].id]
  }

  criteria {
    query                   = file("${path.module}/queries/reservationexpiry.kusto")
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dynamic "dimension" {
      for_each = ["Term_s", "ExpiryDate_s", "Id_s", "DisplayName_s"]
      content {
        name     = dimension.value
        operator = "Include"
        values   = ["*"]
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.this
  ]
}
