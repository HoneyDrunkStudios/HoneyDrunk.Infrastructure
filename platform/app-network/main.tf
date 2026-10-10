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

module "network" {
  source              = "../../modules/networking/app-service"
  name                = "vnet-hd-apps-${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
  network_cidr        = var.network_cidr
  subnet_cidr         = var.subnet_cidr
}
