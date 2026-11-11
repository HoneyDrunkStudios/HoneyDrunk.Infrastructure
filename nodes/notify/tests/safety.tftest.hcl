mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_function_app_flex_consumption.func_hd_notify_dev.runtime_name == "dotnet-isolated" && azurerm_function_app_flex_consumption.func_hd_notify_dev.runtime_version == "11.0"
    error_message = "Notify must use the .NET 11 isolated runtime required by its upgraded worker package."
  }
  assert {
    condition     = azurerm_service_plan.asp_rghdnotifydev_898e.sku_name == "FC1" && azurerm_storage_account.sthdnotifydev.shared_access_key_enabled && azurerm_storage_account.sthdnotifydev.blob_properties[0].delete_retention_policy[0].days == 7
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
