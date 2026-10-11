terraform {
  required_version = "= 1.16.5"
  backend "azurerm" {}
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "= 2.13.0"
    }
  }
}

provider "azapi" {
  tenant_id                  = "f5654adb-2a4c-4317-9217-09ef32ccdd3a"
  subscription_id            = "82073da5-bd6d-4874-947e-73b791054cbc"
  skip_provider_registration = true
}
