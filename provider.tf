terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }

  }
}

provider "azurerm" {
  features {}
  use_cli = true # ← clé : dis au provider d’utiliser le contexte `az` (ton `az account show`)
}


