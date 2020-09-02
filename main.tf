terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=0.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=1.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=2.2.0"
    }
  }
}

# Configure the Microsoft Azure Provider.
provider "azurerm" {
  features {}
}