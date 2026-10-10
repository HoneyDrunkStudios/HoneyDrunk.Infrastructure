# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  subscription_id           = "00000000-0000-4000-8000-000000000001"
  tenant_id                 = "00000000-0000-4000-8000-000000000002"
  existing_assignment_names = { "acr_pull" : "00000000-0000-4000-8000-000000000002", "configuration_reader" : "00000000-0000-4000-8000-000000000002", "vault_reader" : "00000000-0000-4000-8000-000000000002" }
}
run "safe_development_contract" {
  command = plan
}
run "reject_production" {
  command = plan
  variables {
    environment = "prod"
  }
  expect_failures = [var.environment]
}
