# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name      = "example-hd-dev"
  server_id = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Sql/servers/sql-hd-shared-dev"
  subnet_id = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Network/virtualNetworks/vnet-hd-apps-dev/subnets/snet-app-service"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = !azurerm_mssql_virtual_network_rule.this.ignore_missing_vnet_service_endpoint
    error_message = "SQL access must fail if the endpoint is missing."
  }
}
