terraform {
  required_version = "= 1.16.5"
  backend "azurerm" {}
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
  }
}

provider "azuread" {
  tenant_id = "28ad6dfb-254d-41c3-a840-9b2135ed11a6"
}
