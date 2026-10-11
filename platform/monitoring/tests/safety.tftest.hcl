mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_monitor_action_group.azureapp_auto.enabled && azurerm_monitor_action_group.application_insights_smart_detection.enabled
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
