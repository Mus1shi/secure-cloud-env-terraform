data "azurerm_client_config" "current" {}

# ------------------------------------------------------
# Role Assignment : Terraform = Secrets Officer
# ------------------------------------------------------
resource "azurerm_role_assignment" "kv_secrets_officer_tf" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ------------------------------------------------------
# Key Vault
# ------------------------------------------------------
resource "azurerm_key_vault" "kv" {
  name                = var.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Sécurité
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  # ⚠️ Autorisations réseau
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [var.private_subnet_id]   # ton subnet privé
    ip_rules                   = [var.admin_ip_cidr]       # ton IP publique /32
  }

  public_network_access_enabled = true
}

# ------------------------------------------------------
# Secrets
# ------------------------------------------------------

# 1) Clé privée bastion
resource "azurerm_key_vault_secret" "bastion_private_key" {
  count        = var.bastion_private_key_path != null && trimspace(var.bastion_private_key_path) != "" ? 1 : 0
  name         = "bastion-private-key"
  value        = file(var.bastion_private_key_path)
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "application/x-pem-file"
}

# 2) Mot de passe DB (aléatoire)
resource "random_password" "db_pwd" {
  length           = 20
  special          = true
  override_special = "!@#-_"
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_pwd.result
  key_vault_id = azurerm_key_vault.kv.id
}

# ------------------------------------------------------
# Rôles pour la VM privée
# ------------------------------------------------------
resource "azurerm_role_assignment" "kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Reader"
  principal_id         = var.private_vm_principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.private_vm_principal_id
}
