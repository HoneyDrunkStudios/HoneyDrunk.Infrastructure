# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name                = "example-hd-dev"
  resource_group_name = "rg-hd-platform-dev"
  location            = "eastus2"
  tags                = { "hd:node" : "honeydrunk-infrastructure", "hd:env" : "dev", "hd:owner" : "honeydrunkstudios", "hd:cost-center" : "core-infra", "hd:dr-tier" : "T1", "hd:adr" : "ADR-0077" }
  network_cidr        = "10.240.0.0/16"
  subnet_cidr         = "10.240.1.0/27"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_subnet.integration.service_endpoint[0].service == "Microsoft.Sql" && azurerm_subnet.integration.delegation[0].service_delegation[0].name == "Microsoft.Web/serverFarms"
    error_message = "Subnet must carry both service endpoint and App Service delegation."
  }
}
run "reject_outside_subnet" {
  command = plan
  variables {
    subnet_cidr = "10.241.0.0/27"
  }
  expect_failures = [azurerm_subnet.integration]
}
run "reject_tiny_subnet" {
  command = plan
  variables {
    subnet_cidr = "10.240.1.0/29"
  }
  expect_failures = [var.subnet_cidr]
}
run "reject_invalid_cidr" {
  command = plan
  variables {
    network_cidr = "not-a-cidr"
  }
  expect_failures = [var.network_cidr]
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
