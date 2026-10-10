resource "azurerm_application_insights" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  application_type    = "web"
  workspace_id        = var.workspace_id
  lifecycle { prevent_destroy = true }
}
