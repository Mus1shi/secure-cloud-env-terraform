output "keyvault_id" {
  value = try(azurerm_key_vault.kv[0].id, "")
}

output "keyvault_uri" {
  value = try(azurerm_key_vault.kv[0].vault_uri, "")
}

output "keyvault_name" {
  value = try(azurerm_key_vault.kv[0].name, "")
}
