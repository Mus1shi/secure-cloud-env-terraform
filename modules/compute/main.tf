locals {
  use_inline_key = var.ssh_public_key != null && trim(var.ssh_public_key) != ""
}

# Si aucune clé publique fournie : en générer une (tls)
resource "tls_private_key" "bastion" {
  count     = local.use_inline_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Sauvegarder la clé privée localement (pour test rapide). 
# ⚠️ Étape temporaire : on déplacera plus tard la gestion des secrets dans KeyVault.
resource "local_file" "bastion_private_key_pem" {
  count           = local.use_inline_key ? 0 : 1
  filename        = "${path.root}/.ssh/bastion_id_rsa"
  content         = tls_private_key.bastion[0].private_key_pem
  file_permission = "0600"
}

# IP publique
resource "azurerm_public_ip" "bastion" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC
resource "azurerm_network_interface" "bastion" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

# VM Ubuntu
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.bastion.id
  ]

  # Clé publique : celle fournie ou celle générée
  admin_ssh_key {
    username   = var.admin_username
    public_key = local.use_inline_key ? var.ssh_public_key : tls_private_key.bastion[0].public_key_openssh
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
