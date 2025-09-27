# Variables for the compute module (bastion vm).
# Allows flexibility: custom vm name, ssh key, size, image version etc.
# Some typos are left in comments on purpose.

variable "resource_group_name" {
  type = string
  # RG where vm + nic + pip will be created.
}

variable "location" {
  type = string
  # Azure region, should match network module.
}

variable "vm_name" {
  type    = string
  default = "vm-bastion"
  # Default naming, but you can overide for multi vm setups.
}

variable "subnet_id" {
  type = string
  # Subnet id where bastion lives (public subnet).
}

variable "admin_username" {
  type    = string
  default = "azureuser"
  # Default user, can be chnged to something unique.
}

# Optionnal: provide your own ssh key
variable "ssh_public_key" {
  type     = string
  default  = null
  nullable = true
  # If null, a tls key will be generated automatically.
}

# Small size vm for cost efficiency
variable "vm_size" {
  type    = string
  default = "Standard_B1s"
  # Can be scaled up later if you need more perf.
}

# Ubuntu LTS image definition
variable "os_publisher" {
  type    = string
  default = "Canonical"
}
variable "os_offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy"
}
variable "os_sku" {
  type    = string
  default = "22_04-lts-gen2"
}
variable "os_version" {
  type    = string
  default = "latest"
  # Using "latest" keeps vm always deploying newest patch image.
}
