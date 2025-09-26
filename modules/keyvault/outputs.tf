output "keyvault_id" {
  value       = azurerm_key_vault.kv.id
  description = "ID ARM du Key Vault"
}

output "keyvault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Nom du Key Vault"
}

output "keyvault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "URI (https://<name>.vault.azure.net/)"
}

output "bastion_private_key_secret_id" {
  value       = try(azurerm_key_vault_secret.bastion_private_key[0].id, null)
  description = "ID du secret 'ssh-bastion-private-key' (null si non créé)"
}
