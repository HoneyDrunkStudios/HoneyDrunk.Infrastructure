locals {
  tags = {
    "hd:node"        = "honeydrunk-identity"
    "hd:env"         = var.environment
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "identity"
    "hd:dr-tier"     = "T2"
    "hd:adr"         = "ADR-0077"
  }
  platform_group = "rg-hd-platform-${var.environment}"
}

module "database" {
  source    = "../../modules/data/sql-database"
  name      = "sqldb-hd-identity-${var.environment}"
  server_id = var.server_id
  tags      = local.tags
}
