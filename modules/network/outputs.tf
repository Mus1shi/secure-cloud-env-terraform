# Outputs for the network module
# These values are "exported" so root module or other modules can use them.
# Some typos in comment are intentional, code stays safe.

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
  # Useful for linking diagnostics, peering, or other dependant resources.
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
  # Sometimes naming is needed (ex: when referencing NSGs by name in polices).
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
  # Bastion host is deployed here, so id is passed to compute module.
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.private.id
  # Internal VMs (no direct internet) will use this subnet.
}

output "public_nsg_id" {
  description = "ID of the public NSG"
  value       = azurerm_network_security_group.public.id
  # Needed to enable NSG flow logs or pass into monitoring module.
}

output "private_nsg_id" {
  description = "ID of the private NSG"
  value       = azurerm_network_security_group.private.id
  # Same as above, keep it exported in case other resorces needs to hook into it.
}
