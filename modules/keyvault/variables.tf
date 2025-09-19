variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "kv_name" { type = string }

# Subnet autorisé à joindre le KV (via service endpoint)
variable "private_subnet_id" { type = string }

# Identité de la VM privée (pour RBAC)
variable "private_vm_principal_id" { type = string }

# Chemin local de la clé privée bastion (optionnel)
variable "bastion_private_key_path" {
  type     = string
  default  = null
  nullable = true
}

variable "admin_ip_cidr" {
  type = string
}

