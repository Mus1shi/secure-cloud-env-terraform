# LAW
output "law_id"          { value = azurerm_log_analytics_workspace.law.id }
output "law_name"        { value = azurerm_log_analytics_workspace.law.name }
output "law_workspace_id"{ value = azurerm_log_analytics_workspace.law.workspace_id }

# DCR / AMA
output "dcr_id"   { value = azurerm_monitor_data_collection_rule.dcr.id }
output "dcr_name" { value = azurerm_monitor_data_collection_rule.dcr.name }

output "ama_extension_ids" {
  value = [for _, v in azurerm_virtual_machine_extension.ama : v.id]
}
output "dcr_association_ids" {
  value = [for _, v in azurerm_monitor_data_collection_rule_association.dcr_assoc : v.id]
}

# Activity Log / KV diag
output "subscription_activity_diag_id" {
  value = azurerm_monitor_diagnostic_setting.sub_activity.id
}
output "key_vault_diag_id" {
  value = try(azurerm_monitor_diagnostic_setting.kv_diag[0].id, null)
}

# Flow logs / Alertes (option)
output "flowlogs_storage_account_name" {
  value = try(azurerm_storage_account.flowlogs_sa.name, null)
}
output "nsg_flow_log_ids" {
  value = try([for _, v in azurerm_network_watcher_flow_log.flowlog : v.id], [])
}
output "action_group_id" {
  value = try(azurerm_monitor_action_group.ag[0].id, null)
}
output "cpu_alert_ids" {
  value = try([for _, v in azurerm_monitor_metric_alert.cpu_high : v.id], [])
}
