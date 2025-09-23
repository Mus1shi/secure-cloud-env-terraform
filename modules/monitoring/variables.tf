variable "resource_group_name" { type = string }
variable "location"            { type = string }

# IDs des VMs (bastion + privée)
variable "vm_ids" { type = list(string) }

# ID du Key Vault
variable "key_vault_id" { type = string }

# NSG à activer en Flow Logs (public + privé)
variable "nsg_ids" { type = list(string) }

# (Option) email pour recevoir les alertes
variable "alert_email" {
  type    = string
  default = null
}
