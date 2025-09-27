# Variables for the network module (vnet, subnets, nsgs).  
# Using description fields helps to document resources better.  
# Note: a few typos are intencionaly left in comments.

variable "resource_group_name" {
  description = "The name of the resource group where resources will be created"
  type        = string
  # Always pass this from root. Never hardcode, so the module stays reusble.
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  # Keep it consistent across all modules (avoid mixing eastus / westeurope).
}

variable "project_name" {
  description = "Project prefix used for naming resources"
  type        = string
  # Short name that will be re-used in locals to generate names for vnet/subnets/nsgs.
}

variable "vnet_cidr" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
  # Large enouth to host multiple subnets, but small enouf to avoid overlap.
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
  # Bastion (or jump host) is placed here.
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
  # Backend VMs are here, isolated (no public ip).
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (/32) for SSH access"
  type        = string

  validation {
    condition     = can(regex("\\/32$", var.my_ip_cidr))
    error_message = "The value of my_ip_cidr must end with /32."
  }
  # This ensures only a single host IP is whitelisted in NSG rule.
}
