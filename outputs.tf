output "action_group_id" {
  value       = one(azurerm_monitor_action_group.eventpipeline[*].id)
  description = "The id of the action group created for the event pipeline."
}

output "windows_dcr_ids" {
  value = [
    azurerm_monitor_data_collection_rule.event_log.id
  ]
  description = "Map of DCRs and their resource IDs that should be associated to windows VMs."
}

output "linux_dcr_ids" {
  value = [
    azurerm_monitor_data_collection_rule.syslog.id
  ]
  description = "Map of DCRs and their resource IDs that should be associated to linux VMs."
}

output "vminsights_dcr_id" {
  value       = azurerm_monitor_data_collection_rule.vm_insight.id
  description = "Resource ID of the VM-Insights DCR that should be associated with every VM."
}

 
output "scheduled_query_rules_v2" {
  description = "A map of the Scheduled Query Rule Alert V2 resources. Contains the full configuration for each alert, including the rendered KQL queries, action groups, and evaluation settings."
  value       = azurerm_monitor_scheduled_query_rules_alert_v2.this
}