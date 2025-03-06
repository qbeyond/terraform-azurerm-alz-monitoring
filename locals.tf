locals {
  path                    = "${path.module}/queries"
  service_uri             = replace(var.event_pipeline_config.service_uri, "{{secret}}", var.secret)
  service_uri_integration = replace(var.event_pipeline_config.service_uri, "{{secret}}", var.secret_integration)

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
      frequency   = "PT5M"
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

  customer_code = upper(split("-", regex("fctkey-[^-]+", var.event_pipeline_config.service_uri_integration))[1])

  # Add <name> = <directory> entries for each function you want to add to the monitoring function app.
  # Note: the <name> must correspond to the variable function_config.stage_<name>
  # Note: the directory is the name of the subdirectory in /functions where the function code is located
  all_functions = {
    sql = "sql_monitor"
  }

  sql_key_vault_name = format("kv-%s-sqlmonitor-01", local.customer_code)

  # Exclude source code of all functions that are not specified or specifically set to "off"
  excluded_functions = [for key, path in local.all_functions : path if lookup(var.functions_config.stages, key, "off") == "off"]
  enabled_functions = [for key, path in local.all_functions : key if lookup(var.functions_config.stages, key, "off") != "off"]

  # Checks that the event pipeline and at least one function is enabled
  enable_function_app = var.event_pipeline_config.enabled && length(local.excluded_functions) < length(local.all_functions)
}
