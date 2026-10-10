# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name                      = "example-hd-dev"
  resource_group_name       = "rg-hd-platform-dev"
  location                  = "eastus2"
  tags                      = { "hd:node" : "honeydrunk-infrastructure", "hd:env" : "dev", "hd:owner" : "honeydrunkstudios", "hd:cost-center" : "core-infra", "hd:dr-tier" : "T1", "hd:adr" : "ADR-0077" }
  environment_id            = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.App/managedEnvironments/cae-hd-dev"
  container_name            = "pulse"
  image                     = "example.azurecr.io/pulse@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  candidate_revision_suffix = "candidate"
  serving_revision_suffix   = "retained"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_container_app.this.revision_mode == "Multiple" && !azurerm_container_app.this.ingress[0].traffic_weight[0].latest_revision && azurerm_container_app.this.ingress[0].traffic_weight[0].revision_suffix == "retained"
    error_message = "Candidate configuration must retain explicit serving traffic."
  }
}
run "reject_floating_image" {
  command = plan
  variables {
    image = "example.azurecr.io/pulse:latest"
  }
  expect_failures = [var.image]
}
run "reject_latest_traffic" {
  command = plan
  variables {
    serving_revision_suffix = "latest"
  }
  expect_failures = [var.serving_revision_suffix]
}
run "reject_literal_secret" {
  command = plan
  variables {
    secret_references = { "api-key" : "literal-not-a-uri" }
  }
  expect_failures = [var.secret_references]
}
run "accept_key_vault_reference" {
  command = plan
  variables {
    secret_references            = { api-key = "https://kv-hd-pulse-dev.vault.azure.net/secrets/TestKey" }
    secret_environment_variables = { API_KEY = "api-key" }
  }
  assert {
    condition     = one(azurerm_container_app.this.secret).key_vault_secret_id == "https://kv-hd-pulse-dev.vault.azure.net/secrets/TestKey"
    error_message = "Only the Key Vault URI should be represented in the configuration."
  }
}
run "reject_missing_secret_reference" {
  command = plan
  variables { secret_environment_variables = { API_KEY = "missing" } }
  expect_failures = [var.secret_environment_variables]
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
