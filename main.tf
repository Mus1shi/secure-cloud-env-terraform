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

  vm_name   = "vm-bastion"
  subnet_id = module.network.public_subnet_id
  admin_username = "azureuser"
  vm_size = "Standard_B1s"

  
}

