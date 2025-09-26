################
# ROOT OUTPUTS #
################

# Bastion
output "bastion_public_ip" {
  value = module.compute.public_ip
}

output "bastion_admin_username" {
  value = module.compute.admin_username
}

output "bastion_private_key_path" {
  value = module.compute.private_key_path
}

# VM privée
output "private_vm_ip" {
  value = module.compute_private.private_ip
}

output "private_vm_admin_username" {
  value = module.compute_private.admin_username
}

output "private_vm_key_path" {
  value = module.compute_private.private_key_path
}

# Key Vault (peut être désactivé)
output "keyvault_name" {
  value = try(module.keyvault[0].keyvault_name, "(disabled)")
}

output "keyvault_uri" {
  value = try(module.keyvault[0].keyvault_uri, "(disabled)")
}