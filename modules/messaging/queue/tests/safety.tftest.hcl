# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name         = "example-hd-dev"
  namespace_id = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ServiceBus/namespaces/sb-hd-shared-dev"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_servicebus_queue.this.dead_lettering_on_message_expiration && azurerm_servicebus_queue.this.max_delivery_count == 10
    error_message = "Lifecycle queues must dead-letter expired/poison messages."
  }
  assert {
    condition     = azurerm_servicebus_queue.this.requires_duplicate_detection && azurerm_servicebus_queue.this.duplicate_detection_history_time_window == "PT10M" && !azurerm_servicebus_queue.this.partitioning_enabled
    error_message = "Lifecycle queues must preserve duplicate detection and nonpartitioned ordering."
  }
}
