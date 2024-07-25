terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
  required_version = ">=1.5.0"
}
