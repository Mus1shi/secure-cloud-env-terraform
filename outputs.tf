################
# ROOT OUTPUTS #
################

# Bastion related info
# public IP is what u use to ssh into it
output "bastion_public_ip" {
  value = module.compute.public_ip
}

# default username for the VM
output "bastion_admin_username" {
  value = module.compute.admin_username
}

# path where the ssh private key got generated (locally)
output "bastion_private_key_path" {
  value = module.compute.private_key_path
}

# ---- Private VM ----
# internal IP only (no public exposure)
output "private_vm_ip" {
  value = module.compute_private.private_ip
}

output "private_vm_admin_username" {
  value = module.compute_private.admin_username
}

output "private_vm_key_path" {
  value = module.compute_private.private_key_path
}

# ---- Key Vault ----
# if KV module is disabled → output is just "(disabled)"
output "keyvault_name" {
  value = try(module.keyvault[0].keyvault_name, "(disabled)")
}

output "keyvault_uri" {
  value = try(module.keyvault[0].keyvault_uri, "(disabled)")
}
