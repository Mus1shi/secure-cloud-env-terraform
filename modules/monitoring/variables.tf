# modules/monitoring/variables.tf

variable "resource_group_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "key_vault_id" {
  description = "ID ARM du Key Vault"
  type        = string
}

variable "nsg_ids" {
  description = "Liste d'IDs ARM des NSG (pour Flow Logs si activé)"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email destinataire des alertes (optionnel)"
  type        = string
  default     = ""
}

# On utilise UNIQUEMENT vm_map (et plus vm_ids)
variable "vm_map" {
  description = "Map stable des VMs: { name = resource_id }"
  type        = map(string)
}

# Désactivé par défaut (beaucoup d'environnements le bloquent)
variable "enable_nsg_flow_logs" {
  description = "Activer NSG Flow Logs (peut être bloqué selon l'env)"
  type        = bool
  default     = false
}
