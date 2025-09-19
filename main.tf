resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-secure"
  location = "westeurope"
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  project_name        = "secureenv"
  vnet_cidr           = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  my_ip_cidr          = var.my_ip_cidr
}


module "compute" {
  source              = "./modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name        = "vm-bastion"
  subnet_id      = module.network.public_subnet_id
  admin_username = "azureuser"
  vm_size        = "Standard_B1s"


}

module "compute_private" {
  source              = "./modules/compute_private"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  vm_name            = "vm-private"
  subnet_id          = module.network.private_subnet_id
  public_subnet_cidr = "10.0.1.0/24" # ton subnet public

  admin_username = "azureuser"
  vm_size        = "Standard_B1s"

}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kv_name                 = "kv-secureenv-${random_string.suffix.result}"
  private_subnet_id       = module.network.private_subnet_id
  private_vm_principal_id = module.compute_private.vm_principal_id

  # on pousse la clé privée bastion si elle a été générée par Terraform
  bastion_private_key_path = module.compute.private_key_path
  admin_ip_cidr            = var.my_ip_cidr

}

# suffix aléatoire pour nom globalement unique
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}
