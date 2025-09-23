variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# IDs ARM des VMs (bastion + privée)
variable "vm_ids" {
  type = list(string)
}

# ID ARM complet du Key Vault
variable "key_vault_id" {
  type = string
}

# IDs ARM des NSG (utilisés uniquement si enable_nsg_flow_logs = true)
variable "nsg_ids" {
  type    = list(string)
  default = []
}

# Email pour recevoir les alertes (facultatif)
variable "alert_email" {
  type    = string
  default = null
}

# ⚠️ NSG Flow Logs sont bloqués par Microsoft (création interdite depuis 30/06/2025)
# On laisse à false par défaut pour éviter l'erreur.
variable "enable_nsg_flow_logs" {
  type    = bool
  default = false
}
