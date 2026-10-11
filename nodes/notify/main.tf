# Releases own package/app settings and deployment storage authentication material.
# Infrastructure manages hosting, identity, storage, scale and network configuration.
# Empty API IP-restriction default representations are preserved; rules stay managed.
resource "azurerm_service_plan" "asp_rghdnotifydev_898e" {
  app_service_environment_id      = null
  location                        = "eastus2"
  maximum_elastic_worker_count    = 1
  name                            = "ASP-rghdnotifydev-898e"
  os_type                         = "Linux"
  per_site_scaling_enabled        = false
  premium_plan_auto_scale_enabled = false
  resource_group_name             = "rg-hd-notify-dev"
  sku_name                        = "FC1"
  tags = {
    "env"  = "dev"
    "node" = "notify"
  }
  zone_balancing_enabled = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "azure_webjobs_hosts" {
  container_access_type = "private"
  metadata = {
  }
  name               = "azure-webjobs-hosts"
  storage_account_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.Storage/storageAccounts/sthdnotifydev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "app_package_func_hd_notify_dev_333f832" {
  container_access_type = "private"
  metadata = {
  }
  name               = "app-package-func-hd-notify-dev-333f832"
  storage_account_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.Storage/storageAccounts/sthdnotifydev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "azure_webjobs_secrets" {
  container_access_type = "private"
  metadata = {
  }
  name               = "azure-webjobs-secrets"
  storage_account_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.Storage/storageAccounts/sthdnotifydev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "kv_hd_notify_dev" {
  access_policy                   = []
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  location                        = "eastus2"
  name                            = "kv-hd-notify-dev"
  public_network_access_enabled   = true
  purge_protection_enabled        = false
  rbac_authorization_enabled      = true
  resource_group_name             = "rg-hd-notify-dev"
  sku_name                        = "standard"
  soft_delete_retention_days      = 90
  tags = {
    "env"  = "dev"
    "node" = "notify"
  }
  tenant_id = "f5654adb-2a4c-4317-9217-09ef32ccdd3a"
  network_acls {
    bypass                     = "None"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "sthdnotifydev" {
  access_tier                       = "Hot"
  account_kind                      = "StorageV2"
  account_replication_type          = "LRS"
  account_tier                      = "Standard"
  allow_nested_items_to_be_public   = false
  allowed_copy_scope                = null
  cross_tenant_replication_enabled  = false
  default_to_oauth_authentication   = false
  dns_endpoint_type                 = "Standard"
  edge_zone                         = null
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = false
  is_hns_enabled                    = false
  large_file_share_enabled          = false
  local_user_enabled                = true
  location                          = "eastus2"
  min_tls_version                   = "TLS1_2"
  name                              = "sthdnotifydev"
  nfsv3_enabled                     = false
  provisioned_billing_model_version = null
  public_network_access             = "Enabled"
  queue_encryption_key_type         = "Service"
  resource_group_name               = "rg-hd-notify-dev"
  sftp_enabled                      = false
  shared_access_key_enabled         = true
  table_encryption_key_type         = "Service"
  tags = {
    "env"  = "dev"
    "node" = "notify"
  }
  blob_properties {
    change_feed_enabled      = false
    last_access_time_enabled = false
    versioning_enabled       = false
    container_delete_retention_policy {
      days = 7
    }
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }
  share_properties {
    retention_policy {
      days = 7
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_function_app_flex_consumption" "func_hd_notify_dev" {
  app_settings = {
  }
  client_certificate_enabled         = false
  client_certificate_exclusion_paths = null
  client_certificate_mode            = "Required"
  enabled                            = true
  https_only                         = true
  instance_memory_in_mb              = 2048
  location                           = "eastus2"
  maximum_instance_count             = 100
  name                               = "func-hd-notify-dev"
  public_network_access_enabled      = true
  resource_group_name                = "rg-hd-notify-dev"
  runtime_name                       = "dotnet-isolated"
  runtime_version                    = "10.0"
  service_plan_id                    = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.Web/serverFarms/ASP-rghdnotifydev-898e"
  storage_access_key                 = azurerm_storage_account.sthdnotifydev.primary_access_key
  storage_authentication_type        = "StorageAccountConnectionString"
  storage_container_endpoint         = "https://sthdnotifydev.blob.core.windows.net/app-package-func-hd-notify-dev-333f832"
  storage_container_type             = "blobContainer"
  storage_user_assigned_identity_id  = null
  tags = {
    "env"                                    = "dev"
    "hidden-link: /app-insights-resource-id" = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/microsoft.insights/components/appi-hd-notify-dev"
    "node"                                   = "notify"
  }
  virtual_network_subnet_id                      = null
  webdeploy_publish_basic_authentication_enabled = false
  auth_settings {
    additional_login_parameters = {
    }
    allowed_external_redirect_urls = []
    enabled                        = false
    issuer                         = null
    token_refresh_extension_hours  = 0
    token_store_enabled            = false
  }
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
  site_config {
    api_definition_url                            = null
    api_management_api_id                         = null
    app_command_line                              = null
    application_insights_connection_string        = azurerm_application_insights.appi_hd_notify_dev.connection_string
    application_insights_key                      = null
    container_registry_managed_identity_client_id = null
    container_registry_use_managed_identity       = false
    default_documents                             = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php"]
    elastic_instance_minimum                      = 0
    health_check_path                             = null
    http2_enabled                                 = false
    ip_restriction_default_action                 = null
    load_balancing_mode                           = "LeastRequests"
    managed_pipeline_mode                         = "Integrated"
    minimum_tls_version                           = "1.2"
    remote_debugging_enabled                      = false
    runtime_scale_monitoring_enabled              = false
    scm_ip_restriction_default_action             = null
    scm_minimum_tls_version                       = "1.2"
    scm_use_main_ip_restriction                   = false
    use_32_bit_worker                             = false
    vnet_route_all_enabled                        = false
    websockets_enabled                            = false
    worker_count                                  = 1
    cors {
      allowed_origins     = ["https://portal.azure.com"]
      support_credentials = false
    }
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [app_settings, storage_access_key, zip_deploy_file, site_config[0].scm_ip_restriction_default_action, site_config[0].ip_restriction_default_action]
  }
}

resource "azurerm_application_insights" "appi_hd_notify_dev" {
  application_type                     = "web"
  daily_data_cap_in_gb                 = 100
  daily_data_cap_notifications_enabled = true
  force_customer_storage_for_profiler  = false
  internet_ingestion_enabled           = true
  internet_query_enabled               = true
  ip_masking_enabled                   = true
  local_authentication_enabled         = true
  location                             = "eastus2"
  name                                 = "appi-hd-notify-dev"
  resource_group_name                  = "rg-hd-notify-dev"
  retention_in_days                    = 90
  sampling_percentage                  = 0
  tags = {
    "env"  = "dev"
    "node" = "notify"
  }
  workspace_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_queue" "notify_queue" {
  metadata = {
  }
  name               = "notify-queue"
  storage_account_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.Storage/storageAccounts/sthdnotifydev"
  lifecycle {
    prevent_destroy = true
  }
}
