# Outputs for the compute module (bastion vm)
# These values can be used by root or other modules (ex: monitoring)
# Note: typos are intencionaly left in comments.

output "public_ip" {
  value = azurerm_public_ip.bastion.ip_address
  # Exposes the bastion public IP adress (handy for ssh tests).
}

output "private_key_path" {
  value       = try(local_file.bastion_private_key_pem[0].filename, null)
  description = "Chemin local de la clé privée."
  # Only filled if no ssh key was given and tls keypair was generated.
}

output "admin_username" {
  value = var.admin_username
  # Useful if we want to remind what user to ssh with.
}

# ← ID de la VM bastion
output "vm_id" {
  value = azurerm_linux_virtual_machine.bastion.id
  # Exposing vm_id lets monitoring or extensions target this specific vm.
}
