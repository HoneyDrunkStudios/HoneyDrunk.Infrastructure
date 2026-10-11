mock_provider "azurerm" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azurerm_role_assignment.existing_8ea0ac7b_13dc_4963_a60c_9504057974c2.principal_id == "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe" && azurerm_role_assignment.existing_8ea0ac7b_13dc_4963_a60c_9504057974c2.scope == "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc"
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
