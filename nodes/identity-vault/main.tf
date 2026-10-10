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

module "vault" {
  source              = "../../modules/secrets/key-vault"
  name                = "kv-hd-identity-${var.environment}"
  resource_group_name = "rg-hd-identity-${var.environment}"
  location            = var.location
  tags                = local.tags
  tenant_id           = var.tenant_id
}

module "diagnostics" {
  source             = "../../modules/observability/diagnostics"
  target_resource_id = module.vault.id
  workspace_id       = var.workspace_id
  log_categories     = ["AuditEvent"]
}
