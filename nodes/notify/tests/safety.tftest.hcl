mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_service_plan.asp_rghdnotifydev_898e.sku_name == "FC1" && azurerm_storage_account.sthdnotifydev.shared_access_key_enabled && azurerm_storage_account.sthdnotifydev.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
