mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_resource_group.rg_hd_identity_dev.name == "rg-hd-identity-dev" && azurerm_resource_group.defaultresourcegroup_eus2.location == "eastus2"
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
