terraform {
  required_version = "= 1.16.5"
  backend "azurerm" {}
  required_providers {
    msgraph = {
      source  = "Microsoft/msgraph"
      version = "= 0.6.0"
    }
  }
}

provider "msgraph" {
  tenant_id = "28ad6dfb-254d-41c3-a840-9b2135ed11a6"
  use_cli   = true
}
