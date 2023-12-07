locals {
    path = "${path.module}/queries"

    rules = merge({
        "alr-prd-Heartbeat-ux-law-log-crit-01": {
            description = "Alert when Heartbeat of unix machines Stopped"
            query_path  = "${local.path}/unix_heartbeat.kusto"
            time_window = 2280
        }
        "alr-prd-Diskspace-ux-law-log-warn-crit-01": {
            description = "Alert when filesystem of unix runs out of space"
            query_path  = "${local.path}/unix_filespace.kusto"
            time_window = 2280
        }
        "alr-prd-Diskspace-ux-law-log-warn-crit-02": {
            description = "Alert when SAP Filespace runs out of space"
            query_path = "${local.path}/unix_sap_filespace.kusto"
            time_window = 2280
        }

        "alr-prd-Eventlog6008-win-law-log-crit-01": {
            description = "Alert when the Windows event 6008 (unexpected shutdown) was logged"
            query_path  = "${local.path}/windows_event_6008.kusto"
            time_window = 30
        }
        "alr-prd-Eventlog55-win-law-log-crit-01": {
            description = "Alert when the Windows event 55 (disk corruption) was logged"
            query_path  = "${local.path}/windows_event_55.kusto"
            time_window = 30
        }

        "alr-prd-Heartbeat-win-law-log-crit-01": {
            description = "Alert when Heartbeat from Windows machines Stopped"
            query_path  = "${local.path}/windows_heartbeat.kusto"
            time_window = 2280
        }
        "alr-prd-Diskspace-win-law-log-warn-crit-01": {
            description = "Alert when filesystem of windows runs out of space"
            query_path  = "${local.path}/windows_filespace.kusto"
            time_window = 2280
        }
        "alr-prd-VMBackup-bkp-law-log-warn-01": {
            description = "Alert when a VM backup job fails"
            query_path  = "${local.path}/vm_backup.kusto"
            time_window = 2280
        }
    }, var.additional_queries)
}
