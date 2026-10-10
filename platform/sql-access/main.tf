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

module "app_service_rule" {
  source    = "../../modules/data/sql-subnet-rule"
  name      = "app-service-${var.environment}"
  server_id = var.server_id
  subnet_id = var.subnet_id
}
