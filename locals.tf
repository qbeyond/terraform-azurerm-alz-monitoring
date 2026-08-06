locals {
  path = "${path.module}/queries"

  default_queries = {
    mssql = {
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
    }
    default = {
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
      "alr-prd-runbook-law-autom-warn-01" : {
        description = "Alert for custom text monitoring logs"
        query_path  = "${local.path}/runbook_law_autom.kusto"
        time_window = "PT15M"
        frequency   = "PT5M"
      }
      "alr-prd-AzureHeartbeat-law-logsea-warn-01" : {
        description = "Alert when Azure VMs stop sending heartbeat data"
        query_path  = "${local.path}/azureheartbeat.kusto"
        time_window = "PT15M"
        frequency   = "PT5M"
      }
      "alr-prd-bkppolicy-win-ux-law-aresm-warn-01" : {
        description = "Alert when Azure VM has no backup policy assigned"
        query_path  = "${local.path}/windows_bkppolicy.kusto"
        time_window = "P1D"
        frequency   = "P1D"

        include_failing_periods = {
          minimum_failing_periods_to_trigger_alert = 1
          number_of_evaluation_periods             = 1
        }

        identity = {
          type         = "UserAssigned"
          identity_ids = [azurerm_user_assigned_identity.this.id]
        }
      }
      "alr-prd-CustLogJson-winux-law-logsea-crit-01" : {
        description = "Alert for custom json monitoring logs"
        query_path  = "${local.path}/custlogjson_winux_prd.kusto"
        time_window = "PT15M"
        frequency   = "PT5M"
      }
    }
  }

  # Selects the queries that have been chosen via var.features
  # Defaults to the "default" alert rules only.
  selected_queries = merge(
    [for feat, enabled in var.features :
      lookup(local.default_queries, feat, {})
      if enabled
    ]...
  )

  empty_query_object = {
    query_path                = null
    description               = null
    time_window               = "P2D"
    frequency                 = "PT5M"
    non_productive            = false
    display_name              = null
    query_time_range_override = null
    enabled                   = true
    severity                  = 0
    skip_query_validation     = true
    target_resource_types = [
      "microsoft.compute/virtualmachines",
      "microsoft.hybridcompute/machines",
      "microsoft.compute/virtualmachinescalesets"
    ]
    include_failing_periods = null
    identity                = null
  }

  # Expands each rule object to contain all attributes (using default values if not specified).
  # If the same alert rule appears in both the selected default rules AND var.additional_queries,
  # then the attributes from var.additional_queries override the defaults.
  rules = {
    # Iterate over all distinct keys in both selected_queries (defaults) and additional_queries (custom)
    for key in setunion(
      keys(local.selected_queries),
      keys(var.additional_queries)
    ) :
    key => merge(
      local.empty_query_object,             # Empty object with all default attributes
      try(local.selected_queries[key], {}), # overridden by qby defaults, if specified
      try(var.additional_queries[key], {})  # overridden by custom values, if specified
    )
  }

  event_rule = {
    "alr-prd-Eventlog-win-law-logsea-crit-warn-01" : {
      description = "Alert when the Windows event was logged"
      query_path  = "${local.path}/windows_event.kusto.tftpl"
      time_window = "PT30M"
      frequency   = "PT5M"
    }
  }

  event_rules_processed = {
    for key, value in local.event_rule :
    key => merge(local.empty_query_object, value)
  }

  all_alertrules = merge(
    local.rules,
    length(local.selected_events) > 0 ? local.event_rules_processed : {}
  )

  customer_code = var.event_pipeline_config.service_uri == "" ? var.customer_code : upper(split("-", regex("fctkey-[^-]+", var.event_pipeline_config.service_uri))[1])
}
