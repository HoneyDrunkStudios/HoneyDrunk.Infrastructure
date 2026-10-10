resource "azurerm_service_plan" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  os_type             = "Linux"
  sku_name            = "B1"
  worker_count        = 1
  lifecycle { prevent_destroy = true }
}
