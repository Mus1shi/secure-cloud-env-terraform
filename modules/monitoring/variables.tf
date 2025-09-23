variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_id" {
  type        = string
  description = "L'ID de la VM à laquelle associer la Data Collection Rule"
}

variable "nsg_ids" {
  type        = list(string)
  description = "Liste des Network Security Groups à monitorer avec les flow logs"
}
