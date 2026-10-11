mock_provider "azuread" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azuread_application.identity_api.sign_in_audience == "AzureADMyOrg" && azuread_application.pocket_quests_web.sign_in_audience == "AzureADMyOrg"
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
