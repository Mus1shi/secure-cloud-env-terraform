output "dashboard_id" {
  description = "ID ARM complet du dashboard"
  value       = azapi_resource.dashboard.id
}

output "dashboard_name" {
  description = "Nom du dashboard"
  value       = var.dashboard_name
}

output "dashboard_url" {
  description = "URL directe vers le dashboard dans le portail Azure"
  value       = "https://portal.azure.com/#@/dashboard/arm${azapi_resource.dashboard.id}"
}
