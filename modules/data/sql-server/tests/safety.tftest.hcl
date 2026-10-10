# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name                    = "example-hd-dev"
  resource_group_name     = "rg-hd-platform-dev"
  location                = "eastus2"
  tags                    = { "hd:node" : "honeydrunk-infrastructure", "hd:env" : "dev", "hd:owner" : "honeydrunkstudios", "hd:cost-center" : "core-infra", "hd:dr-tier" : "T1", "hd:adr" : "ADR-0077" }
  administrator_name      = "Synthetic workforce group"
  administrator_object_id = "00000000-0000-4000-8000-000000000002"
  tenant_id               = "00000000-0000-4000-8000-000000000002"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_mssql_server.this.azuread_administrator[0].azuread_authentication_only && azurerm_mssql_server.this.minimum_tls_version == "1.2"
    error_message = "SQL must require Entra auth and TLS 1.2."
  }
  assert {
    condition     = azurerm_mssql_server.this.public_network_access_enabled
    error_message = "Classic SQL service endpoints require the public endpoint with restricted access."
  }
}
run "reject_invalid_admin" {
  command = plan
  variables {
    administrator_object_id = "not-a-guid"
  }
  expect_failures = [var.administrator_object_id]
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
