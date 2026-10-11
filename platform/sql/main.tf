locals {
  tags = {
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:env"         = var.environment
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:adr"         = "ADR-0077"
  }
  platform_group = "rg-hd-platform-${var.environment}"
}

module "server" {
  depends_on              = [azurerm_resource_provider_registration.sql]
  source                  = "../../modules/data/sql-server"
  name                    = "sql-hd-shared-${var.environment}"
  resource_group_name     = local.platform_group
  location                = var.location
  tags                    = local.tags
  administrator_name      = var.administrator_name
  administrator_object_id = var.create_administrator_group ? azuread_group.sql_administrators[0].object_id : var.administrator_object_id
  tenant_id               = var.tenant_id
}
