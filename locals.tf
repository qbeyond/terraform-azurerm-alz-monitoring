locals {
    path = "${path.module}/queries"

    law_name = ""
    law_rg = ""

    rules = {
        "alr-prd-heartbeat-ux-law-perf-crit-01": {
            description = "Alert when Heartbeat Stopped"
            query_path = "${path}/unix_heartbeat.kusto"
        }
        "alr-prd-diskspace-ux-law-perf-warn-crit-01": {
            description = "Alert when Filespace runs out of space"
            query_path = "${path}/unix_filespace.kusto"
        }
        "alr-prd-diskspace-ux-law-perf-warn-crit-02": {
            description = "Alert when SAP Filespace runs out of space"
            query_path = "${path}/unix_sap_filespace.kusto"
        }

        "alr-prd-eventlog6008-win-law-event-crit-01": {
            description = "Alert when the Windows event log entries occurred"
            query_path = "${path}/windows_event_6008.kusto"
        }
        "alr-prd-eventlog55-win-law-event-crit-01": {
            description = "Alert when the Windows event log entries occurred"
            query_path = "${path}/windows_event_55.kusto"
        }

        "alr-prd-heartbeat-win-law-perf-crit-01": {
            description = "Alert when Heartbeat Stopped"
            query_path = "${path}/windows_heartbeat.kusto"
        }
        "alr-prd-diskspace-win-law-perf-warn-crit-01": {
            description = "Alert when Filespace runs out of space"
            query_path = "${path}/windows_filespace.kusto"
        }
    }
}