mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_container_app.ca_hd_pulse_dev.revision_mode == "Multiple" && azurerm_container_app.ca_hd_pulse_dev.ingress[0].target_port == 8080
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
