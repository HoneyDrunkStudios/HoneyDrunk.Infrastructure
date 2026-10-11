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
  tenant_id = "f5654adb-2a4c-4317-9217-09ef32ccdd3a"
}
