#####################################
# ROOT MAIN.TF – SECURE CLOUD ENV  #
#####################################

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

  # Doit exister dans variables.tf à la racine (ex: "X.X.X.X/32")
  my_ip_cidr = var.my_ip_cidr
}

# 3) VM Bastion (publique)
module "compute" {
  source              = "./modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name        = "vm-bastion"
  subnet_id      = module.network.public_subnet_id
  admin_username = "azureuser"
  vm_size        = "Standard_B1s"
}

# 4) VM privée (dans subnet privé)
module "compute_private" {
  source              = "./modules/compute_private"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name            = "vm-private"
  subnet_id          = module.network.private_subnet_id
  public_subnet_cidr = "10.0.1.0/24" # subnet public

  admin_username = "azureuser"
  vm_size        = "Standard_B1s"
}

# 5) Suffixe aléatoire (noms globaux uniques)
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

# 6) Key Vault (+ secrets)
module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kv_name                 = "kv-secureenv-${random_string.suffix.result}"
  private_subnet_id       = module.network.private_subnet_id
  private_vm_principal_id = module.compute_private.vm_principal_id

  # on pousse la clé privée bastion si générée par Terraform
  bastion_private_key_path = module.compute.private_key_path
  admin_ip_cidr            = var.my_ip_cidr
}

# 7) Monitoring (LAW, DCR, AMA, Activity Log, alertes)
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Map stable {nom logique => id ARM} (évite l’erreur for_each)
  vm_map = {
    bastion = module.compute.vm_id
    private = module.compute_private.vm_id
  }

  key_vault_id = module.keyvault.keyvault_id

  nsg_ids = [
    module.network.public_nsg_id,
    module.compute_private.private_nsg_id,
  ]

  # Optionnel (déclenche la création d’un Action Group + Alerts)
  alert_email = "tommyprobx@hotmail.com"

  # Laisse à false (Microsoft a gelé la création de NSG Flow Logs côté API)
  enable_nsg_flow_logs = false
}

#####################################
# (Optionnel) Dashboard via azapi   #
# Gardé en commentaire pour plus tard
#####################################
# module "dashboard" {
#   source              = "./modules/dashboard"
#   dashboard_name      = "dash-secure-cloud-env"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

