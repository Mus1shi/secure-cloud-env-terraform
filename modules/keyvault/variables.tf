variable "resource_group_name" {
   type = string 
   }
variable "location" { 
  type = string 
  }
variable "kv_name" { 
  type = string 
  }
variable "private_vm_principal_id" {
   type = string
    default = "" 
    }
variable "bastion_private_key_path" { 
  type = string
   default = "" 
   }
variable "admin_ip_cidr" { 
  type = string
   default = "" 
   }
variable "enabled" {
   type = bool
    default = false 
    } # important: false par défaut
