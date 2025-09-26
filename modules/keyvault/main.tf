# modules/keyvault/main.tf
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  count               = var.enabled ? 1 : 0
  name                = var.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.admin_ip_cidr != "" ? [var.admin_ip_cidr] : []
  }
}

resource "random_password" "db_pwd" {
  count   = var.enabled ? 1 : 0
  length  = 20
  special = true
}

resource "azurerm_key_vault_secret" "db_pwd" {
  count        = var.enabled ? 1 : 0
  name         = "db-password"
  value        = random_password.db_pwd[0].result
  key_vault_id = azurerm_key_vault.kv[0].id
}

resource "azurerm_key_vault_secret" "bastion_ssh_key" {
  count        = var.enabled && var.bastion_private_key_path != "" ? 1 : 0
  name         = "bastion-ssh-private-key"
  value        = file(var.bastion_private_key_path)
  key_vault_id = azurerm_key_vault.kv[0].id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  count               = var.enabled && var.private_vm_principal_id != "" ? 1 : 0
  scope               = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id        = var.private_vm_principal_id
}
