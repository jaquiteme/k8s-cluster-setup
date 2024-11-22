terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5"
    }
  }

  required_version = ">= 1.9.2"
}

# Azure provider config
provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}
