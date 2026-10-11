# The developer App Configuration SKU has no soft-delete retention.
# AzureRM reports an unset Log Analytics local-auth property as null. Preserve both
# service-owned representations; security changes require a distinct reviewed plan.
resource "azurerm_container_app_environment" "cae_hd_dev" {
  dapr_application_insights_connection_string = null
  infrastructure_resource_group_name          = null
  infrastructure_subnet_id                    = null
  location                                    = "eastus2"
  log_analytics_workspace_id                  = null
  logs_destination                            = "azure-monitor"
  mutual_tls_enabled                          = false
  name                                        = "cae-hd-dev"
  public_network_access                       = "Enabled"
  resource_group_name                         = "rg-hd-platform-dev"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:owner"       = "honeydrunkstudios"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_container_registry" "acrhdshareddev" {
  admin_enabled                                = false
  anonymous_pull_enabled                       = false
  azuread_authentication_as_arm_policy_enabled = true
  data_endpoint_enabled                        = false
  encryption                                   = []
  export_policy_enabled                        = true
  location                                     = "eastus2"
  name                                         = "acrhdshareddev"
  network_rule_bypass_for_tasks_enabled        = false
  network_rule_bypass_option                   = "AzureServices"
  network_rule_set                             = []
  public_network_access_enabled                = true
  quarantine_policy_enabled                    = false
  resource_group_name                          = "rg-hd-platform-dev"
  retention_policy_in_days                     = 0
  role_assignment_mode                         = "LegacyRegistryPermissions"
  sku                                          = "Basic"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:owner"       = "honeydrunkstudios"
  }
  zone_redundancy_enabled = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag_to_law" {
  eventhub_authorization_rule_id = null
  eventhub_name                  = null
  log_analytics_workspace_id     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-dev"
  name                           = "diag-to-law"
  partner_solution_id            = null
  storage_account_id             = null
  target_resource_id             = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourcegroups/rg-hd-platform-dev/providers/microsoft.app/managedenvironments/cae-hd-dev"
  enabled_log {
    category       = "ContainerAppConsoleLogs"
    category_group = null
  }
  enabled_log {
    category       = "ContainerAppSystemLogs"
    category_group = null
  }
  enabled_metric {
    category = "AllMetrics"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr_audit_to_loganalytics" {
  eventhub_authorization_rule_id = null
  eventhub_name                  = null
  log_analytics_workspace_id     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-dev"
  name                           = "acr-audit-to-loganalytics"
  partner_solution_id            = null
  storage_account_id             = null
  target_resource_id             = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourcegroups/rg-hd-platform-dev/providers/microsoft.containerregistry/registries/acrhdshareddev"
  enabled_log {
    category       = "ContainerRegistryLoginEvents"
    category_group = null
  }
  enabled_log {
    category       = "ContainerRegistryRepositoryEvents"
    category_group = null
  }
  enabled_metric {
    category = "AllMetrics"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_log_analytics_workspace" "log_hd_shared_dev" {
  allow_resource_only_permissions         = true
  cmk_for_query_forced                    = false
  daily_quota_gb                          = -1
  data_collection_rule_id                 = null
  immediate_data_purge_on_30_days_enabled = false
  internet_ingestion_access_type          = "Enabled"
  internet_query_access_type              = "Enabled"
  local_authentication_enabled            = null
  location                                = "eastus2"
  name                                    = "log-hd-shared-dev"
  reservation_capacity_in_gb_per_day      = null
  resource_group_name                     = "rg-hd-platform-dev"
  retention_in_days                       = 30
  sku                                     = "PerGB2018"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:owner"       = "honeydrunkstudios"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [local_authentication_enabled]
  }
}

resource "azurerm_app_configuration" "appcs_hd_shared_dev" {
  data_plane_proxy_authentication_mode             = "Pass-through"
  data_plane_proxy_private_link_delegation_enabled = false
  local_auth_enabled                               = false
  location                                         = "eastus2"
  name                                             = "appcs-hd-shared-dev"
  public_network_access                            = null
  purge_protection_enabled                         = false
  resource_group_name                              = "rg-hd-platform-dev"
  sku                                              = "developer"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:owner"       = "honeydrunkstudios"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [soft_delete_retention_days]
  }
}

resource "azurerm_servicebus_namespace" "sb_hd_shared_dev" {
  capacity                      = 0
  local_auth_enabled            = true
  location                      = "eastus2"
  minimum_tls_version           = "1.2"
  name                          = "sb-hd-shared-dev"
  premium_messaging_partitions  = 0
  public_network_access_enabled = true
  resource_group_name           = "rg-hd-platform-dev"
  sku                           = "Standard"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:owner"       = "honeydrunkstudios"
  }
  network_rule_set {
    default_action                = "Allow"
    ip_rules                      = []
    public_network_access_enabled = true
    trusted_services_allowed      = false
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_servicebus_namespace_authorization_rule" "rootmanagesharedaccesskey" {
  listen       = true
  manage       = true
  name         = "RootManageSharedAccessKey"
  namespace_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ServiceBus/namespaces/sb-hd-shared-dev"
  send         = true
  lifecycle {
    prevent_destroy = true
  }
}
