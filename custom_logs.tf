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

output "tests" {
  value = local.kql_types
}

output "test2" {
  value = "source | parse-kv RawData as (${local.kql_types}) with (pair_delimiter=\";\",kv_delimiter=\":\") | project-away RawData"

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

#region dcr text logs?
# resource "azurerm_monitor_data_collection_rule" "custom_log" {
#   name                        = "dcr-prd-win-CustomLog-01"
#   resource_group_name         = var.log_analytics_workspace.resource_group_name
#   location                    = var.log_analytics_workspace.location
#   tags                        = var.tags
#   description                 = "Collect custom log data for monitoring"
#   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id

#   destinations {
#     log_analytics {
#       workspace_resource_id = var.log_analytics_workspace.id
#       name                  = var.log_analytics_workspace.name
#     }
#   }

#   data_flow {
#     streams       = ["Custom-Format"]
#     destinations  = [var.log_analytics_workspace.name]
#     output_stream = "Custom-MonitoringScripts_CL"
#     transform_kql = "source | parse-kv RawData as (${local.kql_types}) with (pair_delimiter=\";\",kv_delimiter=\":\") | project-away RawData"
#   }

#   data_sources {
#     log_file {
#       name          = "Custom-Text_Win_CL"
#       format        = "text"
#       streams       = ["Custom-Format"]
#       file_patterns = ["c:\\program files\\ud\\logs\\*.log"]
#       settings {
#         text {
#           record_start_timestamp_format = "ISO 8601"
#         }
#       }
#     }
#   }

#   stream_declaration {
#     stream_name = "Custom-Format"
#     column {
#       name = "TimeGenerated"
#       type = "datetime"
#     }
#     column {
#       name = "RawData"
#       type = "string"
#     }

#   }
#   depends_on = [azapi_resource.data_collection_logs_table]
# }
#endregion


resource "azapi_resource" "data_collection_rule" {
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
