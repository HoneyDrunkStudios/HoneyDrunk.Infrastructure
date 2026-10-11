mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_servicebus_namespace.sb_hd_shared_dev.sku == "Standard" && azurerm_servicebus_namespace.sb_hd_shared_dev.local_auth_enabled && azurerm_app_configuration.appcs_hd_shared_dev.sku == "developer" && !azurerm_app_configuration.appcs_hd_shared_dev.local_auth_enabled
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}

run "preserve_resource_ids_output" {
  command = plan
  assert {
    condition = toset(keys(output.resource_ids)) == toset([
      "log_analytics_workspace", "container_app_environment", "registry",
      "app_configuration", "service_bus",
    ])
    error_message = "Consumers must retain the five non-secret platform ID keys."
  }
}
