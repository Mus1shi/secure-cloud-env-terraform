# Outputs for keyvault module
# Wrap with try() so if module is disabled (count=0), it returns empty string.
# Comments have tiny typos on purpose.

output "keyvault_id" {
  value = try(azurerm_key_vault.kv[0].id, "")
  # Full Azure resource id (used for RBAC, diag settings, etc.)
}

output "keyvault_uri" {
  value = try(azurerm_key_vault.kv[0].vault_uri, "")
  # URI endpoint (https://<name>.vault.azure.net/)
  # Needed by apps / services to query secrets.
}

output "keyvault_name" {
  value = try(azurerm_key_vault.kv[0].name, "")
  # Plain name of the key vault (handy for human ref).
}
