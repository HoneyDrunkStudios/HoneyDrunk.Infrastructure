output "resource_ids" {
  description = "Non-secret references; distribute approved IDs without granting access to platform state."
  value = {
    log_analytics_workspace   = azurerm_log_analytics_workspace.log_hd_shared_dev.id
    container_app_environment = azurerm_container_app_environment.cae_hd_dev.id
    registry                  = azurerm_container_registry.acrhdshareddev.id
    app_configuration         = azurerm_app_configuration.appcs_hd_shared_dev.id
    service_bus               = azurerm_servicebus_namespace.sb_hd_shared_dev.id
  }
}
