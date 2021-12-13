terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.86.0"
    }
  }
}

provider "azurerm" {
  features {
  # resource_group {
  #    prevent_deletion_if_contains_resources = true
  #    }
  }
 }
