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
  subnet_id       = null
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_resource_provider_registration.quota.name == "Microsoft.Quota"
    error_message = "Register only the API needed for the approved B1 quota request."
  }
}
run "reject_production" {
  command = plan
  variables {
    environment = "prod"
  }
  expect_failures = [var.environment]
}
run "reject_wrong_subnet_id" {
  command = plan
  variables { subnet_id = "/subscriptions/00000000-0000-4000-8000-000000000099/resourceGroups/wrong/providers/Example/wrong" }
  expect_failures = [var.subnet_id]
}
run "runtime_has_only_scoped_read_access" {
  command = plan
  assert {
    condition     = azurerm_role_assignment.registry_pull.role_definition_name == "AcrPull" && azurerm_role_assignment.registry_pull.scope == "/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ContainerRegistry/registries/acrhdshareddev"
    error_message = "Runtime registry access must be pull-only on the selected shared registry."
  }
  assert {
    condition     = azurerm_role_assignment.vault_read.role_definition_name == "Key Vault Secrets User" && azurerm_role_assignment.vault_read.scope == "/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-identity-dev/providers/Microsoft.KeyVault/vaults/kv-hd-identity-dev"
    error_message = "Runtime secrets access must be read-only on its own vault."
  }
}

run "reject_old_region" {
  command = plan
  variables { location = "eastus2" }
  expect_failures = [var.location]
}
