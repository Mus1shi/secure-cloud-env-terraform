output "public_subnet_id" {
  value = module.network.public_subnet_id
}
output "bastion_public_ip" {
  value = module.compute.public_ip
}

output "bastion_admin_username" {
  value = module.compute.admin_username
}

output "bastion_private_key_path" {
  value = module.compute.private_key_path
}
