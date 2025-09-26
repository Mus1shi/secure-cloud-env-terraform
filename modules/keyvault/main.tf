################################
# modules/keyvault/main.tf
################################

# Qui déploie ?
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = var.kv_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled

  # Firewall : deny par défaut + IP perso + subnet privé (service endpoint KeyVault activé sur ce subnet)
  public_network_access_enabled = true
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = [var.admin_ip_cidr]
    virtual_network_subnet_ids = [var.private_subnet_id]
  }

  # (Option) Access Policy pour TON compte (si ton tenant n'impose pas RBAC)
  dynamic "access_policy" {
    for_each = var.enable_access_policies ? [1] : []
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      secret_permissions = [
        "Get","List","Set","Delete","Purge","Recover","Restore","Backup"
      ]
      key_permissions = [
        "Get","List","Create","Delete","Purge","Recover","Backup","Restore","Sign","Verify","WrapKey","UnwrapKey","Encrypt","Decrypt"
      ]
      certificate_permissions = [
        "Get","List","Create","Delete","Purge","Recover","Backup","Restore","Import"
      ]
      storage_permissions = []
    }
  }

  tags = {
    project = "secure-cloud-env-terraform"
    env     = "lab"
  }
}

# (Option) RBAC : donner à la VM privée le droit de LIRE les secrets
resource "azurerm_role_assignment" "private_vm_secrets_reader" {
  count                = var.assign_secrets_user_to_private_vm && var.private_vm_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.private_vm_principal_id
}

# (Option) Secret : clé privée du bastion
resource "azurerm_key_vault_secret" "bastion_private_key" {
  count        = var.create_secrets && var.bastion_private_key_path != null ? 1 : 0
  name         = "ssh-bastion-private-key"
  value        = file(var.bastion_private_key_path)
  key_vault_id = azurerm_key_vault.kv.id

  content_type = "text/plain"
  tags = {
    owner = "bastion"
  }
}
