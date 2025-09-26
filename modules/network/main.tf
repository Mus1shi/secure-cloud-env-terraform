terraform {
  required_version = ">= 1.3.0"
}

locals {
  prefix              = var.project_name
  vnet_name           = "${local.prefix}-vnet"
  public_subnet_name  = "${local.prefix}-snet-public"
  private_subnet_name = "${local.prefix}-snet-private"
  nsg_public_name     = "${local.prefix}-nsg-public"
  nsg_private_name    = "${local.prefix}-nsg-private"
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

  service_endpoints = ["Microsoft.KeyVault"]
  address_prefixes  = [var.private_subnet_cidr]
}

############################################
# 3) NSG – Subnet public
############################################
resource "azurerm_network_security_group" "public" {
  name                = local.nsg_public_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Autorise SSH uniquement depuis TON /32
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
# 4) Assoc NSG ↔ Subnet public
############################################
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

############################################
# 5) NSG – Subnet privé (SSH strict via bastion)
############################################
resource "azurerm_network_security_group" "private" {
  name                = local.nsg_private_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Autoriser SSH depuis le subnet public (bastion)
  security_rule {
    name                       = "Allow-SSH-From-Public-Subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_subnet_cidr
    destination_address_prefix = "*"
  }

  # Bloquer SSH depuis le reste du VNet (écrase Default AllowVNet Inbound)
  security_rule {
    name                       = "Deny-SSH-From-VirtualNetwork"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

############################################
# 6) Assoc NSG ↔ Subnet privé
############################################
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}
