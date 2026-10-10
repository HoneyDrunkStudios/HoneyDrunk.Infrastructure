resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  sku                 = var.sku
  admin_enabled       = false
  lifecycle { prevent_destroy = true }
}
