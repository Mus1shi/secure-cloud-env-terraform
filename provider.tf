terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.111.0"
      # We use azurerm provider, minimum version 3.111.0 (quite recent one)
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
      # random provider is used for generate suffix / names etc...
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
  # this tells terraform to use Azure CLI for authentication
  # so it rely on "az login" instead of service principal.
  # Note: very handy for dev/demo, but in prod better use SP + secret
}
