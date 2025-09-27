terraform {
  required_version = ">= 1.3.0"
  # keep TF >= 1.3, features we use are fine with that
}

locals {
  prefix              = var.project_name
  vnet_name           = "${local.prefix}-vnet"
  public_subnet_name  = "${local.prefix}-snet-public"
  private_subnet_name = "${local.prefix}-snet-private"
  nsg_public_name     = "${local.prefix}-nsg-public"
  nsg_private_name    = "${local.prefix}-nsg-private"
  # local naming helpers so names stay consistent and easy to read
}

############################################
# 1) Virtual Network
############################################
resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = [var.vnet_cidr]
  # single address space for the whole vnet (10.0.0.0/16 by default)
  # subnets are carved from this range below
}

############################################
# 2) Subnets
############################################
resource "azurerm_subnet" "public" {
  name                 = local.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [var.public_subnet_cidr]
  # public subnet hosts the bastion; it has a public IP on the VM NIC
}

resource "azurerm_subnet" "private" {
  name                 = local.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  service_endpoints = ["Microsoft.KeyVault"]
  address_prefixes  = [var.private_subnet_cidr]
  # private subnet for internal workloads (no public IPs)
  # we enable Service Endpoint for KeyVault so traffic stays in Azure backbone
}

############################################
# 3) NSG – Public subnet
############################################
resource "azurerm_network_security_group" "public" {
  name                = local.nsg_public_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH only from YOUR /32 public IP (variable my_ip_cidr)
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
  # No other inbound rules here → default deny applies, so it’s safe
}

############################################
# 4) Assoc NSG ↔ Public subnet
############################################
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
  # attach the public NSG to the public subnet. Keep it at subnet level
}

############################################
# 5) NSG – Private subnet (strict SSH via bastion)
############################################
resource "azurerm_network_security_group" "private" {
  name                = local.nsg_private_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH ONLY from the public subnet (where the bastion lives)
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

  # Deny SSH from the rest of the VNet (overrides the default AllowVNet rule)
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

  # With those two rules, only bastion → private SSH is allowed.
  # All other inbound stays blocked (implicit deny at the end anyway).
}

############################################
# 6) Assoc NSG ↔ Private subnet
############################################
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
  # attach the private NSG to the private subnet (enforces the strict model)
}
