# Emplacement
variable "resource_group_name" {
  type        = string
  description = "Resource Group cible"
}
variable "location" {
  type        = string
  description = "Région Azure (ex: westeurope)"
}

# Nom du Key Vault
variable "kv_name" {
  type        = string
  description = "Nom du Key Vault (globalement unique)"
}

# Sécurité réseau
variable "admin_ip_cidr" {
  type        = string
  description = "Ton IP publique /32 autorisée au firewall du KV"
}
variable "private_subnet_id" {
  type        = string
  description = "Subnet privé autorisé au firewall du KV (service endpoint KeyVault requis)"
}

# (Option) Droits d'accès (RBAC / Access Policy) & Secrets
variable "private_vm_principal_id" {
  type        = string
  description = "Object ID (principal) de la VM privée (managed identity) si tu veux lui donner accès au KV"
  default     = null
}
variable "assign_secrets_user_to_private_vm" {
  type        = bool
  description = "Assigner le rôle RBAC 'Key Vault Secrets User' à la VM privée"
  default     = false
}

variable "enable_access_policies" {
  type        = bool
  description = "Créer une access policy pour TON compte (au lieu de RBAC). Laisse false si ton tenant force RBAC."
  default     = false
}

# (Option) Création de secrets
variable "bastion_private_key_path" {
  type        = string
  description = "Chemin local vers la clé privée SSH du bastion pour la stocker en secret"
  default     = null
}
variable "create_secrets" {
  type        = bool
  description = "Créer des secrets (ex: clé privée bastion). Nécessite droits data-plane."
  default     = false
}

# Paramètres KV
variable "soft_delete_retention_days" {
  type        = number
  default     = 30
}
variable "purge_protection_enabled" {
  type        = bool
  default     = true
}
