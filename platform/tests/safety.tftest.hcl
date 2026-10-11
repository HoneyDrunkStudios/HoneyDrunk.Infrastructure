mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_servicebus_namespace.sb_hd_shared_dev.sku == "Standard" && azurerm_servicebus_namespace.sb_hd_shared_dev.local_auth_enabled && azurerm_app_configuration.appcs_hd_shared_dev.sku == "developer" && !azurerm_app_configuration.appcs_hd_shared_dev.local_auth_enabled
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
