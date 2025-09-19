locals {
  use_inline_key = var.ssh_public_key != null && trim(var.ssh_public_key) != ""
}

# Génère une clé si aucune n'est fournie (clé dédiée à la VM privée)
resource "tls_private_key" "private" {
  count     = local.use_inline_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  count           = local.use_inline_key ? 0 : 1
  filename        = "${path.root}/.ssh/private_vm_id_rsa"
  content         = tls_private_key.private[0].private_key_pem
  file_permission = "0600"
}

# NSG strict pour le subnet privé
resource "azurerm_network_security_group" "private" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Autorise SSH uniquement depuis le subnet public (où réside la bastion)
resource "azurerm_network_security_rule" "allow_ssh_from_public_subnet" {
  name                        = "allow-ssh-from-public-subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.public_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private.name
}

# Bloque le trafic Intra-VNet (sinon la règle Azure par défaut AllowVNetInBound 65000 ouvrirait trop large)
resource "azurerm_network_security_rule" "deny_vnet_inbound" {
  name                        = "deny-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private.name
}

# Blocage de sécurité par défaut (tout le reste)
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private.name
}

# Association NSG ↔ subnet privé
resource "azurerm_subnet_network_security_group_association" "private_assoc" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.private.id
}

# NIC (pas d'IP publique)
resource "azurerm_network_interface" "private" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM Linux privée (sans IP publique)
resource "azurerm_linux_virtual_machine" "private" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.private.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.use_inline_key ? var.ssh_public_key : tls_private_key.private[0].public_key_openssh
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  disable_password_authentication = true
}
