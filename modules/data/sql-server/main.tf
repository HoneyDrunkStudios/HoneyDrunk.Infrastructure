resource "azurerm_mssql_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  version             = "12.0"
  minimum_tls_version = "1.2"
  # Public endpoint supports scoped per-IP firewall rules; absence of rules
  # denies public clients. Never add AllowAllWindowsAzureIps.
  public_network_access_enabled = true
  azuread_administrator {
    login_username              = var.administrator_name
    object_id                   = var.administrator_object_id
    tenant_id                   = var.tenant_id
    azuread_authentication_only = true
  }
  lifecycle { prevent_destroy = true }
}
