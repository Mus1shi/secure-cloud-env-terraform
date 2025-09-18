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
  my_ip_cidr          = "<TON.IP.PUBLIQUE>/32" 
}