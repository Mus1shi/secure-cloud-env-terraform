output "public_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

output "private_key_path" {
  value       = try(local_file.bastion_private_key_pem[0].filename, null)
  description = "Chemin local de la clé privée."
}

output "admin_username" {
  value = var.admin_username
}
