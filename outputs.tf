output "action_group_id" {
  value       = one(azurerm_monitor_action_group.eventpipeline[*].id)
  description = "The id of the action group created for the event pipeline."
}
