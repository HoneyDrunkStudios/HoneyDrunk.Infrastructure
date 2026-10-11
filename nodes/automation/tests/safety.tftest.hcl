mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_key_vault.kv_hd_automation_dev.rbac_authorization_enabled && azurerm_key_vault.kv_hd_automation_dev.soft_delete_retention_days == 90 && !azurerm_key_vault.kv_hd_automation_dev.purge_protection_enabled
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
