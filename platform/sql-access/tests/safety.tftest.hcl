# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_linux_web_app" {
    defaults = {
      location                 = "centralus"
      outbound_ip_address_list = ["203.0.113.10", "203.0.113.11"]
    }
  }
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
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = length(azurerm_mssql_firewall_rule.workstation) == 0
    error_message = "Persistent workstation access requires an explicit selection."
  }
  assert {
    condition     = length(azurerm_mssql_firewall_rule.operator) == 0
    error_message = "Operator access must be absent outside a reviewed window."
  }
  assert {
    condition     = length(azurerm_mssql_firewall_rule.identity_egress) == 2 && alltrue([for ip, rule in azurerm_mssql_firewall_rule.identity_egress : rule.start_ip_address == ip && rule.end_ip_address == ip])
    error_message = "Only each current Identity egress address may be allowed, never an IP range."
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
run "persistent_workstation_is_one_ip_without_maintenance_access" {
  command = plan
  variables { workstation_access = { name = "existing-workstation", ipv4 = "203.0.113.7" } }
  assert {
    condition     = length(azurerm_mssql_firewall_rule.workstation) == 1 && azurerm_mssql_firewall_rule.workstation["existing-workstation"].start_ip_address == "203.0.113.7" && azurerm_mssql_firewall_rule.workstation["existing-workstation"].end_ip_address == "203.0.113.7" && length(azurerm_mssql_firewall_rule.operator) == 0
    error_message = "Durable workstation access must preserve the chosen name and grant one IP without reopening a maintenance window."
  }
}
run "reject_workstation_range" {
  command = plan
  variables { workstation_access = { name = "existing-workstation", ipv4 = "203.0.113.0/24" } }
  expect_failures = [var.workstation_access]
}
run "reject_workstation_maintenance_name_collision" {
  command = plan
  variables { workstation_access = { name = "NOV-SCHEMA-WINDOW", ipv4 = "203.0.113.7" } }
  expect_failures = [var.workstation_access]
}
run "reject_workstation_runtime_name_collision" {
  command = plan
  variables { workstation_access = { name = "Identity-Egress-203-0-113-7", ipv4 = "203.0.113.7" } }
  expect_failures = [var.workstation_access]
}
run "reject_workstation_bypass" {
  command = plan
  variables { workstation_access = { name = "existing-workstation", ipv4 = "0.0.0.0" } }
  expect_failures = [var.workstation_access]
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
run "reject_wrong_app_region" {
  command = plan
  override_data {
    target = data.azurerm_linux_web_app.identity
    values = { location = "eastus2", outbound_ip_address_list = ["203.0.113.10"] }
  }
  expect_failures = [data.azurerm_linux_web_app.identity]
}
run "reject_empty_app_addresses" {
  command = plan
  override_data {
    target = data.azurerm_linux_web_app.identity
    values = { location = "centralus", outbound_ip_address_list = ["", " "] }
  }
  expect_failures = [data.azurerm_linux_web_app.identity]
}
run "reject_runtime_bypass" {
  command = plan
  override_data {
    target = data.azurerm_linux_web_app.identity
    values = { location = "centralus", outbound_ip_address_list = ["0.0.0.0"] }
  }
  expect_failures = [azurerm_mssql_firewall_rule.identity_egress]
}

run "azure_trailing_delimiter_is_not_an_address" {
  command = plan
  override_data {
    target = data.azurerm_linux_web_app.identity
    values = { location = "centralus", outbound_ip_address_list = ["203.0.113.10", "", " "] }
  }
  assert {
    condition     = length(azurerm_mssql_firewall_rule.identity_egress) == 1 && azurerm_mssql_firewall_rule.identity_egress["203.0.113.10"].end_ip_address == "203.0.113.10"
    error_message = "Blank delimiter elements must not create a rule or hide real addresses."
  }
}

run "malformed_nonblank_address_fails_closed" {
  command = plan
  override_data {
    target = data.azurerm_linux_web_app.identity
    values = { location = "centralus", outbound_ip_address_list = ["203.0.113.10", "not-an-ip"] }
  }
  expect_failures = [azurerm_mssql_firewall_rule.identity_egress]
}
