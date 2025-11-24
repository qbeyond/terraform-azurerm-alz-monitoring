locals {
  path = "${path.module}/queries"

  rules = merge({
    "alr-prd-AzureserviceSQL-win-law-metric-crit-01" : {
      description = "Alerts when Azure SQL DB is not available"
      query_path  = "${local.path}/sql_availability.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
    "alr-prd-AzureserviceSQL-win-law-metric-crit-02" : {
      description = "Alerts when no availability metrics for Azure SQL DBs are available"
      query_path  = "${local.path}/sql_no_availability.kusto"
      time_window = "P2D"
      frequency   = "PT5M"
    }
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
    "alr-prd-Backup-bkp-law-logsea-warn-01" : {
      description = "Alert when a backup job fails"
      query_path  = "${local.path}/backup.kusto.tftpl"
      time_window = "P2D"
      frequency   = "PT1H"
    }
    "alr-int-CustLogJson-winux-law-logsea-warn-01" : {
      description    = "Alert for custom json monitoring logs"
      query_path     = "${local.path}/monitoring_scripts_json.kusto"
      time_window    = "PT15M"
      frequency      = "PT5M"
      non_productive = true
    }
    "alr-prd-CustLogText-winux-law-logsea-warn-01" : {
      description = "Alert for custom text monitoring logs"
      query_path  = "${local.path}/monitoring_scripts_text.kusto"
      time_window = "PT15M"
      frequency   = "PT5M"
    }
  }, var.additional_queries)

  event_rule = {
    "alr-prd-Eventlog-win-law-logsea-crit-warn-01" : {
      description = "Alert when the Windows event was logged"
      query_path  = "${local.path}/windows_event.kusto.tftpl"
      time_window = "PT30M"
      frequency   = "PT5M"
    }
  }

  all_alertrules = merge(
    local.rules,
    length(local.selected_events) > 0 ? local.event_rule : {}
  )

  customer_code = var.event_pipeline_config.service_uri == "" ? var.customer_code : upper(split("-", regex("fctkey-[^-]+", var.event_pipeline_config.service_uri))[1])

}

locals {
  default_location = "westeurope"
  tags = {
    "Environment" = "Production"
    "ManagedBy"   = "q.beyond"
    "project"     = ""
  }
}
