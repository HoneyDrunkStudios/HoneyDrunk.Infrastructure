resource "azurerm_resource_provider_registration" "network" {
  name = "Microsoft.Network"
  lifecycle { prevent_destroy = true }
}
