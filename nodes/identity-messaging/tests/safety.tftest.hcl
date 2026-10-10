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
  namespace_id    = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ServiceBus/namespaces/sb-hd-shared-dev"
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
run "reject_wrong_namespace_id" {
  command = plan
  variables { namespace_id = "/subscriptions/00000000-0000-4000-8000-000000000099/resourceGroups/wrong/providers/Example/wrong" }
  expect_failures = [var.namespace_id]
}
