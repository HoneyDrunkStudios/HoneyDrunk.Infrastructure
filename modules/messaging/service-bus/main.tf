resource "azurerm_servicebus_namespace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  sku                 = "Standard"
  minimum_tls_version = "1.2"
  # Preserve the observed live configuration during adoption. Disabling SAS
  # requires a separate consumer audit and access-change approval.
  local_auth_enabled = var.local_auth_enabled
  lifecycle { prevent_destroy = true }
}
