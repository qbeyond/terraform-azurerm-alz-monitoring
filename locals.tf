locals {
  action_group = one(azurerm_monitor_action_group.eventpipeline[*].id) != null ? [one(azurerm_monitor_action_group.eventpipeline[*].id)] : []

  path = "${path.module}/queries"

  rules = merge({
    "alr-prd-Heartbeat-ux-law-metric-crit-01" : {
      description = "Alert when Heartbeat of unix machines Stopped"
      query_path  = "${local.path}/unix_heartbeat.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-Diskspace-ux-law-metric-warn-crit-01" : {
      description = "Alert when filesystem of unix runs out of space"
      query_path  = "${local.path}/unix_filespace.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-Diskspace-ux-law-metric-warn-crit-02" : {
      description = "Alert when SAP Filespace runs out of space"
      query_path  = "${local.path}/unix_sap_filespace.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }

    "alr-prd-Eventlog6008-win-law-logsea-crit-01" : {
      description = "Alert when the Windows event 6008 (unexpected shutdown) was logged"
      query_path  = "${local.path}/windows_event_6008.kusto"
      time_window = "PT30M"
      frequency   = "PT5M"
    }
    "alr-prd-Eventlog55-win-law-logsea-crit-01" : {
      description = "Alert when the Windows event 55 (disk corruption) was logged"
      query_path  = "${local.path}/windows_event_55.kusto"
      time_window = "PT30M"
      frequency   = "PT5M"
    }

    "alr-prd-Heartbeat-win-law-metric-crit-01" : {
      description = "Alert when Heartbeat from Windows machines Stopped"
      query_path  = "${local.path}/windows_heartbeat.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-Diskspace-win-law-metric-warn-crit-01" : {
      description = "Alert when filesystem of windows runs out of space"
      query_path  = "${local.path}/windows_filespace.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-VMBackup-bkp-law-logsea-warn-01" : {
      description = "Alert when a VM backup job fails"
      query_path  = "${local.path}/vm_backup.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-CustLogJson-winux-law-logsea-warn-01" : {
      description = "Alert for custom json monitoring logs"
      query_path  = "${local.path}/monitoring_scripts_json.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
  }, var.additional_queries)
}
