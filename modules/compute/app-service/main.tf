resource "azurerm_linux_web_app" "this" {
  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  tags                                           = var.tags
  service_plan_id                                = var.plan_id
  virtual_network_subnet_id                      = var.subnet_id
  enabled                                        = false
  https_only                                     = true
  client_affinity_enabled                        = false
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  public_network_access_enabled                  = true
  vnet_image_pull_enabled                        = false
  identity { type = "SystemAssigned" }
  site_config {
    always_on                               = true
    ftps_state                              = "Disabled"
    minimum_tls_version                     = "1.2"
    scm_minimum_tls_version                 = "1.2"
    vnet_route_all_enabled                  = true
    container_registry_use_managed_identity = true
    health_check_path                       = "/"
    health_check_eviction_time_in_min       = 2
    application_stack {
      docker_registry_url = "https://mcr.microsoft.com"
      docker_image_name   = "azuredocs/aci-helloworld@sha256:456a1150aa41340a14c7be1342deda2cde9e6e7df9fde6b8a69de0ae04f92fad"
    }
  }
  app_settings = {
    WEBSITES_PORT                       = "80"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITE_WARMUP_PATH                 = "/"
    WEBSITE_WARMUP_STATUSES             = "200"
    WEBSITES_CONTAINER_START_TIME_LIMIT = "600"
  }
  # Bootstrap creates a stopped placeholder. Approved runtime initialization
  # owns these fields afterwards, alongside the release workflow's image.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [enabled, app_settings, site_config[0].application_stack, site_config[0].health_check_path]
  }
}
