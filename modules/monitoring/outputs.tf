# Outputs for monitoring module
# Expose LAW, DCR, AMA, diagnostics, flow logs and alerts
# Comments may contian small typos, code is untouched.

# LAW
output "law_id" {
  value = azurerm_log_analytics_workspace.law.id
  # Full resource id (used for diag, flowlogs, traffic analytics)
}
output "law_name" {
  value = azurerm_log_analytics_workspace.law.name
  # Plain name of the workspace
}
output "law_workspace_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
  # Needed for AMA traffic analytics integration
}

# DCR / AMA
output "dcr_id" {
  value = azurerm_monitor_data_collection_rule.dcr.id
  # Id of the data collection rule
}
output "dcr_name" {
  value = azurerm_monitor_data_collection_rule.dcr.name
}
output "ama_extension_ids" {
  value = [for _, v in azurerm_virtual_machine_extension.ama : v.id]
  # List of AMA extension ids installed on vms
}
output "dcr_association_ids" {
  value = [for _, v in azurerm_monitor_data_collection_rule_association.dcr_assoc : v.id]
  # Ids of all dcr associations per vm
}

# Activity Log / KV diag
output "subscription_activity_diag_id" {
  value = azurerm_monitor_diagnostic_setting.sub_activity.id
  # Subscription activity logs diag setting id
}
output "key_vault_diag_id" {
  value = try(azurerm_monitor_diagnostic_setting.kv_diag[0].id, null)
  # Only if key vault was enabled, else null
}

# Flow logs / Alertes (option)
output "flowlogs_storage_account_name" {
  value = try(azurerm_storage_account.flowlogs_sa.name, null)
  # Name of the SA storing flow logs (dns constraint → must be unique)
}
output "nsg_flow_log_ids" {
  value = try([for _, v in azurerm_network_watcher_flow_log.flowlog : v.id], [])
  # All flow log ids (1 per NSG if enabled)
}
output "action_group_id" {
  value = try(azurerm_monitor_action_group.ag[0].id, null)
  # Null if no email receiver defined
}
output "cpu_alert_ids" {
  value = try([for _, v in azurerm_monitor_metric_alert.cpu_high : v.id], [])
  # One alert per vm, exported as list
}
