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
  workspace_id    = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-dev"
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
run "reject_wrong_workspace_id" {
  command = plan
  variables { workspace_id = "/subscriptions/00000000-0000-4000-8000-000000000099/resourceGroups/wrong/providers/Example/wrong" }
  expect_failures = [var.workspace_id]
}
run "no_bootstrap_access_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_role_assignment.certificate_installation) == 0
    error_message = "Operator secret write access must be explicitly selected."
  }
}
run "one_temporary_secret_installer" {
  command = plan
  variables { bootstrap_operator_object_id = "00000000-0000-4000-8000-000000000003" }
  assert {
    condition     = length(azurerm_role_assignment.certificate_installation) == 1 && azurerm_role_assignment.certificate_installation["operator"].role_definition_name == "Key Vault Secrets Officer" && azurerm_role_assignment.certificate_installation["operator"].principal_id == var.bootstrap_operator_object_id
    error_message = "Only the reviewed operator may receive the explicit temporary secret installation grant."
  }
}
