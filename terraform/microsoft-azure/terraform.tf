terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5"
    }

    azapi = {
      source = "azure/azapi"
    }

    modtm = {
      source  = "Azure/modtm"
      version = "0.3.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }

  required_version = ">= 1.9.2"
}

# Azure provider config
provider "azurerm" {
  features {
  }
}

# Azure Azapi provider config

provider "azapi" {

}

provider "modtm" {

}

provider "random" {

}