# ============================================
# DASHBOARD AZURE TERRAFORM - VERSION TESTÉE
# ============================================
# Cette version évite tous les pièges identifiés :
# - Pas de création de RG (utilise l'existant)
# - Pas de MarkdownPart (cause ErrorLocatingPartDefinition)
# - LinkListPart avec "href" (pas "url")
# - Composants ClockPart et LinkListPart stables
# ============================================

# Variables d'entrée
variable "dashboard_name" {
  description = "Nom du dashboard"
  type        = string
  default     = "dash-secure-cloud-env"
}

variable "resource_group_name" {
  description = "Nom du RG existant (ne sera PAS créé par ce module)"
  type        = string
  default     = "rg-terraform-secure"
}

variable "location" {
  description = "Localisation Azure"
  type        = string
  default     = "westeurope"
}

# Variables optionnelles pour les métriques (à ajouter après test initial)
variable "vm_bastion_id" {
  description = "Resource ID de la VM Bastion pour métriques CPU (optionnel)"
  type        = string
  default     = ""
}

variable "vm_private_id" {
  description = "Resource ID de la VM Private pour métriques CPU (optionnel)"
  type        = string
  default     = ""
}

variable "time_window_ms" {
  description = "Fenêtre de temps pour les métriques en millisecondes"
  type        = number
  default     = 3600000  # 1 heure
}

variable "enable_metrics" {
  description = "Activer la section métriques CPU (nécessite vm_bastion_id et vm_private_id)"
  type        = bool
  default     = false
}
