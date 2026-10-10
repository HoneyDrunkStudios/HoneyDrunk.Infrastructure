resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  address_space       = [var.network_cidr]
  lifecycle { prevent_destroy = true }
}
resource "azurerm_subnet" "integration" {
  name                 = "snet-app-service"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidr]
  service_endpoint { service = "Microsoft.Sql" }
  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = try(cidrhost(var.network_cidr, 0) == cidrhost("${cidrhost(var.subnet_cidr, 0)}/${split("/", var.network_cidr)[1]}", 0) && tonumber(split("/", var.subnet_cidr)[1]) >= tonumber(split("/", var.network_cidr)[1]), false)
      error_message = "The integration subnet must be inside the approved VNet."
    }
  }
}
