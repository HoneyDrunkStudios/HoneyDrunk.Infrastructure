# Releases own image, env, Key Vault references, revision suffix and serving traffic.
# Azure returns registry identity as system; AzureRM requires System in configuration.
# Ignore only that casing-sensitive identity attribute, not registry or ingress policy.
resource "azurerm_container_app" "ca_hd_pulse_dev" {
  container_app_environment_id = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.App/managedEnvironments/cae-hd-dev"
  max_inactive_revisions       = 0
  name                         = "ca-hd-pulse-dev"
  resource_group_name          = "rg-hd-pulse-dev"
  revision_mode                = "Multiple"
  tags = {
    "hd:adr"         = "ADR-0077"
    "hd:cost-center" = "observability"
    "hd:dr-tier"     = "T2"
    "hd:env"         = "dev"
    "hd:node"        = "honeydrunk-pulse"
    "hd:owner"       = "honeydrunkstudios"
  }
  workload_profile_name = null
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
  ingress {
    allow_insecure_connections = false
    client_certificate_mode    = null
    external_enabled           = true
    target_port                = 8080
    transport                  = "auto"
    traffic_weight {
      label           = null
      latest_revision = false
      percentage      = 100
      revision_suffix = "ca-37998537759-1"
    }
  }
  registry {
    identity             = "System"
    password_secret_name = null
    server               = "acrhdshareddev.azurecr.io"
    username             = null
  }
  secret {
    identity            = "System"
    key_vault_secret_id = "https://kv-hd-pulse-dev.vault.azure.net/secrets/PostHog--ApiKey"
    name                = "kv-0fbf26b1387f172a3"
    value               = null
  }
  secret {
    identity            = "System"
    key_vault_secret_id = "https://kv-hd-pulse-dev.vault.azure.net/secrets/PostHog--ApiKey"
    name                = "posthog-apikey"
    value               = null
  }
  secret {
    identity            = "System"
    key_vault_secret_id = "https://kv-hd-pulse-dev.vault.azure.net/secrets/Sentry--Dsn"
    name                = "kv-58c1e854e54e9766f"
    value               = null
  }
  secret {
    identity            = "System"
    key_vault_secret_id = "https://kv-hd-pulse-dev.vault.azure.net/secrets/Sentry--Dsn"
    name                = "sentry-dsn"
    value               = null
  }
  template {
    cooldown_period_in_seconds       = 300
    max_replicas                     = 10
    min_replicas                     = 0
    polling_interval_in_seconds      = 30
    revision_suffix                  = "ca-37998537759-1"
    termination_grace_period_seconds = 0
    container {
      args    = []
      command = []
      cpu     = 0.25
      image   = "acrhdshareddev.azurecr.io/honeydrunk-pulse-collector:dev-42995b3e25911d704c6d14dba1b32c6e3d791475"
      memory  = "0.5Gi"
      name    = "pulse"
      env {
        name        = "AZURE_KEYVAULT_URI"
        secret_name = null
        value       = "https://kv-hd-pulse-dev.vault.azure.net/"
      }
      env {
        name        = "AZURE_APPCONFIG_ENDPOINT"
        secret_name = null
        value       = "https://appcs-hd-shared-dev.azconfig.io"
      }
      env {
        name        = "ASPNETCORE_ENVIRONMENT"
        secret_name = null
        value       = "Development"
      }
      env {
        name        = "HONEYDRUNK_NODE_ID"
        secret_name = null
        value       = "honeydrunk-pulse"
      }
      env {
        name        = "ASPNETCORE_URLS"
        secret_name = null
        value       = "http://+:8080"
      }
      env {
        name        = "PostHog__ApiKey"
        secret_name = "kv-0fbf26b1387f172a3"
        value       = null
      }
      env {
        name        = "Sentry__Dsn"
        secret_name = "kv-58c1e854e54e9766f"
        value       = null
      }
    }
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [secret, template[0].container[0].image, template[0].container[0].env, template[0].revision_suffix, ingress[0].traffic_weight, registry[0].identity]
  }
}

resource "azurerm_key_vault" "kv_hd_pulse_dev" {
  access_policy                   = []
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  location                        = "eastus2"
  name                            = "kv-hd-pulse-dev"
  public_network_access_enabled   = true
  purge_protection_enabled        = false
  rbac_authorization_enabled      = true
  resource_group_name             = "rg-hd-pulse-dev"
  sku_name                        = "standard"
  soft_delete_retention_days      = 90
  tags = {
    "env"  = "dev"
    "node" = "pulse"
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
