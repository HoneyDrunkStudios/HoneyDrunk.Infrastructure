# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  assignment_name    = "00000000-0000-4000-8000-000000000002"
  scope              = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev"
  principal_id       = "00000000-0000-4000-8000-000000000002"
  role_definition_id = "/subscriptions/00000000-0000-4000-8000-000000000001/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_role_assignment.this.name == var.assignment_name && azurerm_role_assignment.this.scope == var.scope
    error_message = "Adoption must retain the exact assignment UUID and scope."
  }
}
