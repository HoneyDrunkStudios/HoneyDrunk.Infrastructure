mock_provider "azurerm" {}
variables {
  subscription_id    = "00000000-0000-4000-8000-000000000001"
  tenant_id          = "00000000-0000-4000-8000-000000000002"
  operator_object_id = "00000000-0000-4000-8000-000000000003"
  operator_ipv4      = "203.0.113.7"
}
run "restricted_recoverable_backend" {
  command = plan
  assert {
    condition     = !azurerm_storage_account.state.shared_access_key_enabled && !azurerm_storage_account.state.allow_nested_items_to_be_public && azurerm_storage_account.state.network_rules[0].default_action == "Deny" && azurerm_storage_account.state.network_rules[0].bypass == toset(["None"])
    error_message = "No key/anonymous/all-network/trusted-service fallback."
  }
  assert {
    condition     = length(azurerm_storage_container.state) == 16 && alltrue([for c in azurerm_storage_container.state : c.container_access_type == "private"]) && length(azurerm_role_assignment.operator) == 16
    error_message = "Sixteen private containers with independently scoped data access are required."
  }
  assert {
    condition     = azurerm_storage_account.state.blob_properties[0].versioning_enabled && azurerm_storage_account.state.blob_properties[0].delete_retention_policy[0].days == 30 && azurerm_storage_account.state.blob_properties[0].container_delete_retention_policy[0].days == 30
    error_message = "State must retain recovery history."
  }
}
run "reject_range" {
  command = plan
  variables { operator_ipv4 = "203.0.113.0/24" }
  expect_failures = [var.operator_ipv4]
}
run "reject_bypass" {
  command = plan
  variables { operator_ipv4 = "0.0.0.0" }
  expect_failures = [var.operator_ipv4]
}
