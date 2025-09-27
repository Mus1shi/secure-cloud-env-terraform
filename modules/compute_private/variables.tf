# Variables for compute_private module
# Deploys a vm with no public ip, reachable only via bastion.
# Some commments has tiny typos, code remains correct.

variable "resource_group_name" {
  type = string
  # RG where the private vm resources are created.
}

variable "location" {
  type = string
  # Azure region, same as rest of infra.
}

variable "vm_name" {
  type    = string
  default = "vm-private"
  # Default name, can be overriden for multi host setup.
}

variable "subnet_id" {
  type = string
  # Subnet id for the private vm (usually private subnet).
}

# CIDR of the public subnet (for NSG allow rule to bastion only)
variable "public_subnet_cidr" {
  type = string
  # Used in nsg rule: only this cidr can ssh to the private vm.
}

variable "admin_username" {
  type    = string
  default = "azureuser"
  # Default admin user, you can set another one.
}

variable "ssh_public_key" {
  type     = string
  default  = null
  nullable = true
  # If not provided, a tls keypair will be generated.
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
  # Small & cheap vm for test. Can be upsized.
}

# Ubuntu LTS image vars
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
  # "latest" ensures terraform pulls most recent patched image.
}
