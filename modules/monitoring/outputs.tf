output "law_id" {
  value = azurerm_log_analytics_workspace.law.id
}
output "law_name" {
  value = azurerm_log_analytics_workspace.law.name
}
output "law_workspace_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}
output "dcr_id" {
  value = azurerm_monitor_data_collection_rule.dcr.id
}
