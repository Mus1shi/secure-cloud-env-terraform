variable "resource_group_name" { type = string }
variable "location"            { type = string }

# Optionnel : null si Key Vault désactivé
variable "key_vault_id" {
  type    = string
  default = null
}

# ---- VMs ----
# Ancienne interface (liste d'IDs) — FACULTATIVE
variable "vm_ids" {
  description = "Liste d'IDs ARM des VMs (option si vm_map fourni)"
  type        = list(string)
  default     = []
}

# Nouvelle interface (map stable id->id) — FACULTATIVE
variable "vm_map" {
  description = "Map stable des VMs: { id = id } (option si vm_ids fourni)"
  type        = map(string)
  default     = {}
}

# ---- Flow Logs (option) ----
variable "enable_nsg_flow_logs" {
  type    = bool
  default = false
}

variable "nsg_ids" {
  type    = list(string)
  default = []
}

# ---- Alerting (option) ----
variable "alert_email" {
  type    = string
  default = null
}
