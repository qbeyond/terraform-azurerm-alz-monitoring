locals {
  columns = {
    "state"                  = "string"
    "TimeGenerated"          = "datetime"
    "additional_information" = "string"
    "affected_entity"        = "string"
    "affected_object"        = "string"
    "monitor_description"    = "string"
    "monitor_name"           = "string"
    "monitor_package"        = "string"
    "script_name"            = "string"
    "script_version"         = "string"
    "threshold"              = "string"
    "value"                  = "string"
  }
  kql_types = join(", ", [for column_name, column_type in local.columns : "${column_name}:${column_type}"])

  resource_group_id = regex("^((/[^/]+){4})", var.log_analytics_workspace.id)[0]
}

resource "azapi_resource" "data_collection_json_logs_table" {
  name      = "MonitoringScriptsJSON_CL"
  parent_id = var.log_analytics_workspace.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = jsonencode(
    {
      "properties" : {
        "schema" : {
          "name" : "MonitoringScriptsJSON_CL",
          "columns" : [
            for column_name, column_type in local.columns : {
              "name"        = column_name
              "type"        = column_type
              "description" = ""
            }
          ]
        },
        "retentionInDays" : 30,
        "totalRetentionInDays" : 30
      }
    }
  )
}

resource "azapi_resource" "data_collection_logs_table" {
  name      = "MonitoringScripts_CL"
  parent_id = var.log_analytics_workspace.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = jsonencode(
    {
      "properties" : {
        "schema" : {
          "name" : "MonitoringScripts_CL",
          "columns" : [
            {
              "name" = "TimeGenerated"
              "type" = "datetime"
            },
            {
              "name" = "RawData"
              "type" = "string"
            }
          ]
        },
        "retentionInDays" : 30,
        "totalRetentionInDays" : 30
      }
    }
  )
}

resource "azapi_resource" "dcr_custom_json_logs" {
  type                      = "Microsoft.insights/dataCollectionRules@2023-03-11"
  name                      = "dcr-prd-all-CustomJSONLog-01"
  parent_id                 = local.resource_group_id
  location                  = var.log_analytics_workspace.location
  schema_validation_enabled = false

  body = jsonencode(
    {
      properties = {
        dataFlows = [
          {
            streams = [
              "Custom-MonitoringScriptsJSON_CL"
            ],
            destinations = [
              "${var.log_analytics_workspace.name}"
            ],
            transformKql = "source"
            outputStream = "Custom-MonitoringScriptsJSON_CL"
          }
        ]
        dataSources = {
          logFiles = [
            {
              name         = "Custom-MonitoringScriptsJSON_CL"
              format       = "json"
              streams      = ["Custom-MonitoringScriptsJSON_CL"]
              filePatterns = ["c:\\program files\\ud\\logs\\json\\*.log"]
            }
          ]
        }
        destinations = {
          logAnalytics = [
            {
              name                = var.log_analytics_workspace.name
              workspaceResourceId = var.log_analytics_workspace.id
            }
          ]
        }
        dataCollectionEndpointId = azurerm_monitor_data_collection_endpoint.dce.id
        streamDeclarations = {
          Custom-MonitoringScripts_CL = {
            columns = [
              for column_name, column_type in local.columns : {
                "name" = column_name
                "type" = column_type
              }
            ]
          }
        }
      }
    }
  )
}

resource "azurerm_monitor_data_collection_rule" "dcr_custom_text_logs" {
  name                        = "dcr-prd-all-CustomTextLog-01"
  resource_group_name         = var.log_analytics_workspace.resource_group_name
  location                    = var.log_analytics_workspace.location
  tags                        = var.tags
  description                 = "Collect custom log data for monitoring"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace.id
      name                  = var.log_analytics_workspace.name
    }
  }

  data_flow {
    streams       = ["Custom-MonitoringScripts_CL"]
    destinations  = [var.log_analytics_workspace.name]
    output_stream = "Custom-MonitoringScripts_CL"
    transform_kql = "source"
  }

  data_sources {
    log_file {
      name          = "Custom-MonitoringScripts_CL"
      format        = "text"
      streams       = ["Custom-MonitoringScripts_CL"]
      file_patterns = ["c:\\program files\\ud\\logs\\*.log"]
      settings {
        text {
          record_start_timestamp_format = "ISO 8601"
        }
      }
    }
  }

  stream_declaration {
    stream_name = "Custom-MonitoringScripts_CL"
    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "RawData"
      type = "string"
    }

  }
  depends_on = [azapi_resource.data_collection_logs_table]
}
