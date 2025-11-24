resource "azurerm_resource_group_template_deployment" "terraform-test" {
  name                = "terraform-arm-01"
  resource_group_name = local.management_rg_name
  deployment_mode     = "Incremental"

  template_content = file("${path.module}/eventparser.json")

  parameters_content = jsonencode({
    "workflows_logicapp_name" = {
      value = "logic-${customer_code}-prd-eventparser"
    }
    "tags" = {
      value = local.tags
    }
    "location" = {
      value = local.default_location
    }
    "logicapp_uri" = {
      value = "https://import-azure-alerts-function-app.azurewebsites.net/api/GenericWebhookJS1?code=${var.event_pipeline_key}&clientid=fctkey-${customer_code}-prd-eventpipeline-01" # TODO: vorher: PCMSD1
    }
  })
}
