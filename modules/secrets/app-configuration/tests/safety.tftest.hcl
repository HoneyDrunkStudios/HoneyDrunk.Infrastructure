# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name                = "example-hd-dev"
  resource_group_name = "rg-hd-platform-dev"
  location            = "eastus2"
  tags                = { "hd:node" : "honeydrunk-infrastructure", "hd:env" : "dev", "hd:owner" : "honeydrunkstudios", "hd:cost-center" : "core-infra", "hd:dr-tier" : "T1", "hd:adr" : "ADR-0077" }
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = !azurerm_app_configuration.this.local_auth_enabled && azurerm_app_configuration.this.sku == "developer"
    error_message = "Shared dev configuration must preserve SKU and Entra-only access."
  }
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
