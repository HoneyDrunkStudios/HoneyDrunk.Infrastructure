# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  subscription_id = "00000000-0000-4000-8000-000000000001"
  tenant_id       = "00000000-0000-4000-8000-000000000002"
  server_id       = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Sql/servers/sql-hd-shared-dev"
  subnet_id       = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Network/virtualNetworks/vnet-hd-apps-dev/subnets/snet-app-service"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = length(azurerm_mssql_firewall_rule.operator) == 0
    error_message = "Operator access must be absent outside a reviewed window."
  }
}
run "single_operator_window" {
  command = plan
  variables { operator_ipv4 = "203.0.113.7" }
  assert {
    condition     = length(azurerm_mssql_firewall_rule.operator) == 1 && azurerm_mssql_firewall_rule.operator["nov-schema-window"].start_ip_address == "203.0.113.7" && azurerm_mssql_firewall_rule.operator["nov-schema-window"].end_ip_address == "203.0.113.7"
    error_message = "The maintenance rule must cover exactly one address."
  }
}
run "reject_operator_bypass" {
  command = plan
  variables { operator_ipv4 = "0.0.0.0" }
  expect_failures = [var.operator_ipv4]
}
run "reject_operator_range" {
  command = plan
  variables { operator_ipv4 = "203.0.113.0/24" }
  expect_failures = [var.operator_ipv4]
}
run "reject_production" {
  command = plan
  variables {
    environment = "prod"
  }
  expect_failures = [var.environment]
}
run "reject_wrong_server_id" {
  command = plan
  variables { server_id = "/subscriptions/00000000-0000-4000-8000-000000000099/resourceGroups/wrong/providers/Example/wrong" }
  expect_failures = [var.server_id]
}
run "reject_wrong_subnet_id" {
  command = plan
  variables { subnet_id = "/subscriptions/00000000-0000-4000-8000-000000000099/resourceGroups/wrong/providers/Example/wrong" }
  expect_failures = [var.subnet_id]
}
