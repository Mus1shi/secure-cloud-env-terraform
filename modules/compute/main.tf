# Compute module - Bastion VM (Ubuntu)
# Handles ssh key generation, public ip, nic and the VM itself.
# Comments may contian small typos, code is safe.

locals {
  use_inline_key = var.ssh_public_key != null && trim(var.ssh_public_key) != ""
  # If a ssh key is given in var, we use it. Otherwise we generate a new one.
}

# Generate a ssh keypair if no ssh key was given
resource "tls_private_key" "bastion" {
  count     = local.use_inline_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
  # Strong RSA 4096 bits. Good for secure conection.
}

# Store private key locally (for quick test only)
# ⚠️ Temporary step: later we move this into Azure KeyVault (more secure).
resource "local_file" "bastion_private_key_pem" {
  count           = local.use_inline_key ? 0 : 1
  filename        = "${path.root}/.ssh/bastion_id_rsa"
  content         = tls_private_key.bastion[0].private_key_pem
  file_permission = "0600"
  # chmod 600 equivalent, so key file is protected.
}

# Public IP for the bastion VM
resource "azurerm_public_ip" "bastion" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  # Standard SKU is recomanded, allows zones & better resiliense.
}

# NIC for the VM
resource "azurerm_network_interface" "bastion" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
    # This nic is attched to public subnet and linked to public ip.
  }
}

# The Linux VM itself (Ubuntu image)
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.bastion.id
  ]

  # Use either provided ssh key or generated one
  admin_ssh_key {
    username   = var.admin_username
    public_key = local.use_inline_key ? var.ssh_public_key : tls_private_key.bastion[0].public_key_openssh
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    # Basic managed disk, standard HDD, good for lab.
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
    # Default values usually: Canonical / UbuntuServer / 20.04-LTS / latest
  }

  disable_password_authentication = true
  # Only SSH keys allowed, no password auth.
}
