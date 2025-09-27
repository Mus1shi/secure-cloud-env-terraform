# modules/keyvault/main.tf
# Deploy a Key Vault (optionnal, toggled by var.enabled).
# Stores a random db password and the bastion ssh key if path given.
# Also assign RBAC to private vm identity. 
# Note: comments may contain small typos.

data "azurerm_client_config" "current" {}
# Fetches infos about current Azure client (tenant id, object id etc).

resource "azurerm_key_vault" "kv" {
  count               = var.enabled ? 1 : 0
  name                = var.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  # Purge protection disabled here (ok for lab, in prod better to enable).

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.admin_ip_cidr != "" ? [var.admin_ip_cidr] : []
    # Restrict acces: only admin_ip and AzureServices allowed.
  }
}

# Random db password secret
resource "random_password" "db_pwd" {
  count   = var.enabled ? 1 : 0
  length  = 20
  special = true
  # Generate strong pwd (20 char, includes special chars).
}

resource "azurerm_key_vault_secret" "db_pwd" {
  count        = var.enabled ? 1 : 0
  name         = "db-password"
  value        = random_password.db_pwd[0].result
  key_vault_id = azurerm_key_vault.kv[0].id
  # Store the random db password in the vault.
}

# Store bastion ssh private key if path is given
resource "azurerm_key_vault_secret" "bastion_ssh_key" {
  count        = var.enabled && var.bastion_private_key_path != "" ? 1 : 0
  name         = "bastion-ssh-private-key"
  value        = file(var.bastion_private_key_path)
  key_vault_id = azurerm_key_vault.kv[0].id
  # ⚠️ Storing raw ssh private key is not recommanded, but fine for demo/test.
}

# Role assignment for private vm to read secrets
resource "azurerm_role_assignment" "kv_secrets_user" {
  count                = var.enabled && var.private_vm_principal_id != "" ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.private_vm_principal_id
  # Grants private vm identity acces to read secrets in kv.
}
