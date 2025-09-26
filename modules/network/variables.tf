variable "resource_group_name" {
  description = "The name of the resource group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "project_name" {
  description = "Project prefix used for naming resources"
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (/32) for SSH access"
  type        = string

  validation {
    condition     = can(regex("\\/32$", var.my_ip_cidr))
    error_message = "The value of my_ip_cidr must end with /32."
  }
}
