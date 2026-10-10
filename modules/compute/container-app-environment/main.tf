resource "azurerm_container_app_environment" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  logs_destination    = "azure-monitor"
  # No Log Analytics key: diagnostics reference the workspace by ID.
  # No workload_profile block: the observed dev environment is consumption-only.
  lifecycle { prevent_destroy = true }
}
