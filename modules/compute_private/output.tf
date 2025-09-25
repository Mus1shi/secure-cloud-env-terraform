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

# Attention: cette sortie suppose que l'identité managée est activée sur la VM privée.
# Si tu n'as pas de bloc "identity { type = \"SystemAssigned\" }" dans la VM,
# commente cette sortie ou ajoute l'identity dans la ressource VM.
output "vm_principal_id" {
  value       = azurerm_linux_virtual_machine.private.identity[0].principal_id
  description = "Object ID de l'identité managée de la VM privée"
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.private.id
}

output "private_nsg_id" {
  value = azurerm_network_security_group.private.id
}
