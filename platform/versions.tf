terraform {
  required_version = "= 1.16.5"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.9.0"
    }
  }
}

provider "azurerm" {
  subscription_id                 = "82073da5-bd6d-4874-947e-73b791054cbc"
  tenant_id                       = "f5654adb-2a4c-4317-9217-09ef32ccdd3a"
  resource_provider_registrations = "none"
  storage_use_azuread             = true
  features {
    app_configuration {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted         = false
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }
}
