# Variables for monitoring module
# Allow flexible input for vms, optional KV, NSG flow logs, alerts
# Comments have little typos, code stays valid.

variable "resource_group_name" {
  type = string
  # RG where LAW, DCR, diag settings etc. will be created
}

variable "location" {
  type = string
  # Azure region, must match other modules (ex: westeurope)
}

# Optionnal: key vault id, or null if module is disabled
variable "key_vault_id" {
  type    = string
  default = null
  # Null disables the KV diagnostic settings (count = 0 trick)
}

# ---- VMs ----
# Old interface (list of ids) - facultative
variable "vm_ids" {
  description = "Liste d'IDs ARM des VMs (option si vm_map fourni)"
  type        = list(string)
  default     = []
  # You can pass just a list of vm ids, but map is prefered
}

# New interface (map stable id->id) - facultative
variable "vm_map" {
  description = "Map stable des VMs: { id = id } (option si vm_ids fourni)"
  type        = map(string)
  default     = {}
  # Using a map gives stable keys, good for naming alerts
}

# ---- Flow Logs (option) ----
variable "enable_nsg_flow_logs" {
  type    = bool
  default = false
  # Default false, as NSG flow logs are often disabled for cost reasons
}

variable "nsg_ids" {
  type    = list(string)
  default = []
  # List of NSG ids to enable flow logs on
}

# ---- Alerting (option) ----
variable "alert_email" {
  type    = string
  default = null
  # If null, no action group nor alerts are created
}
