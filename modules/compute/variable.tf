variable "resource_group_name" { type = string }
variable "location"           { type = string }

variable "vm_name" {
  type    = string
  default = "vm-bastion"
}

variable "subnet_id" { type = string }

variable "admin_username" {
  type    = string
  default = "azureuser"
}

# Si tu veux passer une clé publique existante, on l’autorise (optionnel)
variable "ssh_public_key" {
  type      = string
  default   = null
  nullable  = true
}

# Taille VM minimale (économique)
variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

# Image Ubuntu LTS
variable "os_publisher" { 
    type = string 
    default = "Canonical" 
    }
variable "os_offer"     {
     type = string 
     default = "0001-com-ubuntu-server-jammy" 
     }
variable "os_sku"       { 
    type = string 
    default = "22_04-lts-gen2" 
    }
variable "os_version"   { 
    type = string 
    default = "latest" 
    }
