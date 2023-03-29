locals {
    path = "${path.module}/queries"

    rules = {
        "alr-prd-heartbeat-ux-law-perf-crit-01": {
            description = "Alert when Heartbeat of unix machines Stopped"
            query_path = "${local.path}/unix_heartbeat.kusto"
            time_window = 2280
        }
        "alr-prd-diskspace-ux-law-perf-warn-crit-01": {
            description = "Alert when filesystem of unix runs out of space"
            query_path = "${local.path}/unix_filespace.kusto"
            time_window = 2280
        }
        "alr-prd-diskspace-ux-law-perf-warn-crit-02": {
            description = "Alert when SAP Filespace runs out of space"
            query_path = "${local.path}/unix_sap_filespace.kusto"
            time_window = 2280
        }

        "alr-prd-eventlog6008-win-law-event-crit-01": {
            description = "Alert when the Windows event 6008 (unexpected shutdown) was logged"
            query_path = "${local.path}/windows_event_6008.kusto"
            time_window = 30
        }
        "alr-prd-eventlog55-win-law-event-crit-01": {
            description = "Alert when the Windows event 55 (disk corruption) was logged"
            query_path = "${local.path}/windows_event_55.kusto"
            time_window = 30
        }

        "alr-prd-heartbeat-win-law-perf-crit-01": {
            description = "Alert when Heartbeat from Windows machines Stopped"
            query_path = "${local.path}/windows_heartbeat.kusto"
            time_window = 2280
        }
        "alr-prd-diskspace-win-law-perf-warn-crit-01": {
            description = "Alert when filesystem of windows runs out of space"
            query_path = "${local.path}/windows_filespace.kusto"
            time_window = 2280
        }
    }
}