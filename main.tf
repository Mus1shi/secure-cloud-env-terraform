#####################################
# ROOT MAIN.TF – SECURE CLOUD ENV  #
#####################################

locals {
  # Toggle simple : active/désactive le module Key Vault
  enable_keyvault = false
}

# Si le module keyvault est désactivé, kv_id = null
locals {
  kv_id = local.enable_keyvault ? try(module.keyvault[0].keyvault_id, null) : null
}

# 1) Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-secure"
  location = "westeurope"
}

# 2) Réseau
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  project_name        = "secureenv"
  vnet_cidr           = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"

  # Doit exister dans variables.tf à la racine
  my_ip_cidr = var.my_ip_cidr
}

# 3) VM Bastion (publique)
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name        = "vm-bastion"
  subnet_id      = module.network.public_subnet_id
  admin_username = "azureuser"
  vm_size        = "Standard_B1s"
}

# 4) VM privée (dans subnet privé)
module "compute_private" {
  source = "./modules/compute_private"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name            = "vm-private"
  subnet_id          = module.network.private_subnet_id
  public_subnet_cidr = "10.0.1.0/24"
  admin_username     = "azureuser"
  vm_size            = "Standard_B1s"
}

# 5) Suffixe aléatoire (pour Key Vault s’il est activé)
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

# 6) Key Vault (prêt, mais désactivé par défaut)
module "keyvault" {
  source = "./modules/keyvault"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  kv_name = "kv-secureenv-${random_string.suffix.result}"
  private_vm_principal_id = try(module.compute_private.vm_principal_id, "")
  bastion_private_key_path = try(module.compute.private_key_path, "")
  admin_ip_cidr = var.my_ip_cidr
  enabled = false # <- keep false for now
}

# 7) Monitoring (LAW, DCR, AMA, Activity Log, options)
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Compat : on passe vm_ids (le module supporte vm_ids OU vm_map)
  vm_ids = [
    module.compute.vm_id,
    module.compute_private.vm_id
  ]

  # Key Vault (null si module désactivé)
  key_vault_id = local.kv_id

  # NSG à activer en Flow Logs (on passe ceux du module network)
  nsg_ids              = [module.network.public_nsg_id, module.network.private_nsg_id]
  enable_nsg_flow_logs = false

  # Alertes e-mail (mets ton mail ou laisse null pour désactiver)
  alert_email = null
}

