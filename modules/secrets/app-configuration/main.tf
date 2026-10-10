resource "azurerm_app_configuration" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  sku                 = var.sku
  local_auth_enabled  = false
  lifecycle { prevent_destroy = true }
}
