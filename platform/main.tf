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

module "logs" {
  source              = "../modules/observability/log-analytics"
  name                = "log-hd-shared-${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
}

module "environment" {
  source              = "../modules/compute/container-app-environment"
  name                = "cae-hd-${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
}

module "environment_diagnostics" {
  source             = "../modules/observability/diagnostics"
  target_resource_id = module.environment.id
  workspace_id       = module.logs.id
  log_categories     = ["ContainerAppConsoleLogs", "ContainerAppSystemLogs"]
}

module "registry" {
  source              = "../modules/data/container-registry"
  name                = "acrhdshared${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
}

module "configuration" {
  source              = "../modules/secrets/app-configuration"
  name                = "appcs-hd-shared-${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
}

module "messaging" {
  source              = "../modules/messaging/service-bus"
  name                = "sb-hd-shared-${var.environment}"
  resource_group_name = local.platform_group
  location            = var.location
  tags                = local.tags
}
