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
  tenant_id           = "00000000-0000-4000-8000-000000000002"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled && azurerm_key_vault.this.purge_protection_enabled && azurerm_key_vault.this.soft_delete_retention_days == 90
    error_message = "New vault must use RBAC, soft delete and purge protection."
  }
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
