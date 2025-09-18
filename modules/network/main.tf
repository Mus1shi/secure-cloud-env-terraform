terraform {
  required_version = ">= 1.3.0"
}

locals {
  prefix              = var.project_name
  vnet_name           = "${local.prefix}-vnet"
  public_subnet_name  = "${local.prefix}-snet-public"
  private_subnet_name = "${local.prefix}-snet-private"
  nsg_public_name     = "${local.prefix}-nsg-public"
}

############################################
# 1) Virtual Network
############################################
resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = [var.vnet_cidr]
}

############################################
# 2) Subnets
############################################
resource "azurerm_subnet" "public" {
  name                 = local.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [var.public_subnet_cidr]
}

resource "azurerm_subnet" "private" {
  name                 = local.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [var.private_subnet_cidr]
}

############################################
# 3) Network Security Group (pour le subnet public)
############################################
resource "azurerm_network_security_group" "public" {
  name                = local.nsg_public_name
  location            = var.location
  resource_group_name = var.resource_group_name

  // ✅ Règle d'autorisation SSH depuis TON /32 uniquement
  security_rule {
    name                       = "Allow-SSH-From-My-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_cidr
    destination_address_prefix = "*"
  }

}

############################################
# 4) Attacher le NSG au subnet public
############################################
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}
