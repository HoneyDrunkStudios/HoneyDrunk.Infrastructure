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
  plan_id             = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Web/serverFarms/asp-hd-identity-dev"
  subnet_id           = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Network/virtualNetworks/vnet-hd-apps-dev/subnets/snet-app-service"
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_linux_web_app.this.enabled == false && azurerm_linux_web_app.this.https_only && !azurerm_linux_web_app.this.ftp_publish_basic_authentication_enabled && !azurerm_linux_web_app.this.webdeploy_publish_basic_authentication_enabled
    error_message = "Bootstrap must be stopped with HTTPS and publishing credentials disabled."
  }
  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].vnet_route_all_enabled && !azurerm_linux_web_app.this.vnet_image_pull_enabled
    error_message = "Application egress must use integration without private image-pull routing."
  }
  assert {
    condition     = azurerm_linux_web_app.this.virtual_network_subnet_id == var.subnet_id
    error_message = "App must join the approved subnet."
  }
}
run "reject_missing_tags" {
  command = plan
  variables {
    tags = {}
  }
  expect_failures = [var.tags]
}
