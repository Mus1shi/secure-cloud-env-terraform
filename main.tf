#####################################
# ROOT MAIN.TF – SECURE CLOUD ENV  #
#####################################

locals {
  # simple toggle : enable/disable the Key Vault module
  enable_keyvault = false
}

# If KV is disabled, kv_id = null
locals {
  kv_id = local.enable_keyvault ? try(module.keyvault[0].keyvault_id, null) : null
}

# 1) Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-secure"
  location = "westeurope"
  # main container for all resources, always good to keep naming clear
}

# 2) Network module
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  project_name        = "secureenv"
  vnet_cidr           = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"

  # this is required in variables.tf (root)
  my_ip_cidr = var.my_ip_cidr
}

# 3) Bastion VM (public subnet)
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name        = "vm-bastion"
  subnet_id      = module.network.public_subnet_id
  admin_username = "azureuser"
  vm_size        = "Standard_B1s" # small & cheap for demo/test
}

# 4) Private VM (inside private subnet)
module "compute_private" {
  source = "./modules/compute_private"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name            = "vm-private"
  subnet_id          = module.network.private_subnet_id
  public_subnet_cidr = "10.0.1.0/24" # needed for SSH allow rule from bastion
  admin_username     = "azureuser"
  vm_size            = "Standard_B1s"
}

# 5) Random suffix (used in KV name if enabled)
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

# 6) Key Vault (ready but disabled by default)
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kv_name                  = "kv-secureenv-${random_string.suffix.result}"
  private_vm_principal_id  = try(module.compute_private.vm_principal_id, "")
  bastion_private_key_path = try(module.compute.private_key_path, "")
  admin_ip_cidr            = var.my_ip_cidr
  enabled                  = false # keep off, no rights for RBAC atm
}

# 7) Monitoring (LAW, DCR, AMA, diag settings, alerts)
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # compat: module accept vm_ids list
  vm_ids = [
    module.compute.vm_id,
    module.compute_private.vm_id
  ]

  # Key Vault diag, null if disabled
  key_vault_id = local.kv_id

  # NSGs to activate in Flow Logs (we disable for now)
  nsg_ids              = [module.network.public_nsg_id, module.network.private_nsg_id]
  enable_nsg_flow_logs = false

  # optional alert email, can be null
  alert_email = null
}
