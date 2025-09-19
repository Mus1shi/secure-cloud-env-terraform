output "private_ip" {
  value = azurerm_network_interface.private.private_ip_address
}

output "admin_username" {
  value = var.admin_username
}

output "private_key_path" {
  value       = try(local_file.private_key_pem[0].filename, null)
  description = "Chemin local de la clé privée (si générée par Terraform)."
}
