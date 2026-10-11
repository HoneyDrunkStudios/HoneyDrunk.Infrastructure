mock_provider "azuread" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azuread_application_federated_identity_credential.gh_infra_main.subject == "repo:HoneyDrunkStudios/HoneyDrunk.Infrastructure:ref:refs/heads/main"
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
