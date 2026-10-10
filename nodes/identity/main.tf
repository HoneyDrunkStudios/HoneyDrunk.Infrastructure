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

module "plan" {
  source              = "../../modules/compute/app-service-plan"
  name                = "asp-hd-identity-${var.environment}"
  resource_group_name = "rg-hd-identity-${var.environment}"
  location            = var.location
  tags                = local.tags
}

module "app" {
  source              = "../../modules/compute/app-service"
  name                = var.app_name
  resource_group_name = "rg-hd-identity-${var.environment}"
  location            = var.location
  tags                = local.tags
  plan_id             = module.plan.id
  subnet_id           = var.subnet_id
}
