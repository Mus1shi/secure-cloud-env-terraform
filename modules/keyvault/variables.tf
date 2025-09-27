# Variables for keyvault module
# Control deployment of KV, secrets and role assignments
# Comments includes tiny typos, code unchanged.

variable "resource_group_name" {
  type = string
  # RG where the KeyVault will be created
}

variable "location" {
  type = string
  # Azure region
}

variable "kv_name" {
  type = string
  # Name of the KeyVault (must be globally unique)
}

variable "private_vm_principal_id" {
  type    = string
  default = ""
  # Principal id of private vm (system assigned identity). 
  # Empty if not used, then no role assignment.
}

variable "bastion_private_key_path" {
  type    = string
  default = ""
  # Optional: path to bastion ssh private key on local disk.
  # If empty, no secret is created in kv.
}

variable "admin_ip_cidr" {
  type    = string
  default = ""
  # Optional IP allowed to reach KV (in CIDR format /32).
  # If empty, no ip rule is applied (only AzureServices bypass).
}

variable "enabled" {
  type    = bool
  default = false
  # Important: false by default. 
  # Only enable if RBAC + permissions are correctly setup.
}
