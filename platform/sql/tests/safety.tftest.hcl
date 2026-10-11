# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azuread" {}
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  subscription_id         = "00000000-0000-4000-8000-000000000001"
  tenant_id               = "00000000-0000-4000-8000-000000000002"
  administrator_name      = "Synthetic workforce group"
  administrator_object_id = "00000000-0000-4000-8000-000000000002"
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
run "new_group_has_only_reviewed_operator" {
  command = plan
  variables {
    create_administrator_group     = true
    administrator_name             = "sg-hd-sql-admins-dev"
    administrator_member_object_id = "00000000-0000-4000-8000-000000000003"
  }
  assert {
    condition     = azuread_group.sql_administrators[0].security_enabled && !azuread_group.sql_administrators[0].mail_enabled && azuread_group.sql_administrators[0].members == toset([var.administrator_member_object_id]) && azuread_group.sql_administrators[0].owners == toset([var.administrator_member_object_id])
    error_message = "The SQL admin group must contain only its reviewed workforce operator."
  }
  assert {
    condition     = azurerm_resource_provider_registration.sql.name == "Microsoft.Sql"
    error_message = "Only the required SQL provider may be registered by this root."
  }
}
run "missing_group_operator_is_rejected" {
  command = plan
  variables {
    create_administrator_group     = true
    administrator_member_object_id = null
  }
  expect_failures = [azuread_group.sql_administrators]
}
