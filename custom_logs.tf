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

resource "azapi_resource" "dcr_custom_json_logs" {
  type                      = "Microsoft.insights/dataCollectionRules@2023-03-11"
  name                      = "dcr-prd-win-CustomLog-03"
  parent_id                 = var.resource_group.id
  location                  = var.log_analytics_workspace.location
  schema_validation_enabled = false

  body = jsonencode(
    {
      kind = "Windows"
      properties = {
        dataFlows = [
          {
            streams = [
              "Custom-MonitoringScripts_CL"
            ],
            destinations = [
              "${var.log_analytics_workspace.name}"
            ],
            transformKql = "source"
            outputStream = "Custom-MonitoringScripts_CL"
          }
        ]
        dataSources = {
          logFiles = [
            {
              name         = "Custom-MonitoringScripts_CL"
              format       = "json"
              streams      = ["Custom-MonitoringScripts_CL"]
              filePatterns = ["c:\\program files\\ud\\logs\\*.log"]
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
