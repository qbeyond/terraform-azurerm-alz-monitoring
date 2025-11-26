resource "azurerm_resource_group_template_deployment" "this" {
  name                = "terraform-arm-01"
  resource_group_name = var.log_analytics_workspace.resource_group_name
  deployment_mode     = "Incremental"

  template_content = file("${path.module}/eventparser.json")

  parameters_content = jsonencode({
    "workflows_logicapp_name" = {
      value = "logic-${local.customer_code}-prd-eventparser"
    }
    "tags" = {
      value = var.tags
    }
    "location" = {
      value = var.log_analytics_workspace.location
    }
    "logicapp_uri" = {
      value = replace(var.event_pipeline_config.service_uri, "{{secret}}", var.secret)
    }
  })
}
