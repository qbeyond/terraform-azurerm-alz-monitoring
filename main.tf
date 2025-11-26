data "azurerm_subscription" "current" {
}

resource "azurerm_monitor_action_group" "eventpipeline" {
  count               = var.event_pipeline_config.enabled ? 1 : 0
  name                = "EventPipelineCentral_AG_1"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "monitorhook"
  tags                = var.tags

  webhook_receiver {
    name                    = var.event_pipeline_config.name
    service_uri             = replace(var.event_pipeline_config.service_uri, "{{secret}}", var.secret)
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_action_group" "optional" {
  count               = (var.event_pipeline_config.enabled && anytrue([for k, v in local.rules : lookup(v, "non_productive", false)])) ? 1 : 0
  name                = "EventPipelineCentral_AG_2"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "monitorhook"
  tags                = var.tags

  webhook_receiver {
    name                    = var.event_pipeline_config.name
    service_uri             = replace(var.event_pipeline_config.service_uri_integration, "{{secret}}", var.secret_integration)
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each            = local.rules
  name                = each.key
  display_name        = lookup(each.value, "display_name", null)
  location            = var.log_analytics_workspace.location
  resource_group_name = var.log_analytics_workspace.resource_group_name
  tags                = var.tags

  scopes                    = [var.log_analytics_workspace.id]
  description               = each.value.description
  enabled                   = true
  severity                  = 0
  skip_query_validation     = true
  evaluation_frequency      = each.value.frequency
  window_duration           = each.value.time_window
  query_time_range_override = lookup(each.value, "query_time_range_override", null)

  action {
    action_groups = lookup(each.value, "non_productive", false) ? azurerm_monitor_action_group.optional[*].id : azurerm_monitor_action_group.eventpipeline[*].id
  }

  criteria {
    query = templatefile(each.value.query_path, {
      "tenant"     = local.customer_code
      "all_events" = local.selected_events
    })
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dimension {
      name     = "RawData"
      operator = "Include"
      values   = ["*"]
    }

    dynamic "failing_periods" {
      for_each = try(each.value.include_failing_periods, null) != null ? [each.value.include_failing_periods] : []
      content {
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
        number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
      }
    }

    resource_id_column = "_ResourceId"
  }

  target_resource_types = [
    "microsoft.compute/virtualmachines",
    "microsoft.hybridcompute/machines",
    "microsoft.compute/virtualmachinescalesets"
  ]
}

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "dce-prd-${var.log_analytics_workspace.location}-lawEndpoint-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = var.log_analytics_workspace.location
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "additional_dces" {
  for_each            = var.additional_regions
  name                = "dce-prd-${each.value}-endpoint-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  location            = each.value
  tags                = var.tags
}

data "azurerm_logic_app_workflow" "eventparser" {
  name                = "logic-${local.customer_code}-prd-eventparser"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  # depends_on          = [azurerm_monitor_action_group.eventparser]
}

resource "azurerm_monitor_action_group" "eventparser" {
  name                = "ag-${local.customer_code}-prd-eventparser"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  short_name          = "agprdparser"

  logic_app_receiver {
    name                    = "QBY EventParser"
    resource_id             = data.azurerm_logic_app_workflow.eventparser.id
    callback_url            = data.azurerm_logic_app_workflow.eventparser.access_endpoint
    use_common_alert_schema = true
  }
  lifecycle {
    ignore_changes = [logic_app_receiver]
  }
  tags       = var.tags
  depends_on = [data.azurerm_logic_app_workflow.eventparser]
}
