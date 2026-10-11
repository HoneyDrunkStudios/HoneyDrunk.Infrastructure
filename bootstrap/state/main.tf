locals {
  containers = toset([
    "tfstate-bootstrap-dev", "tfstate-app-network-dev", "tfstate-sql-dev",
    "tfstate-sql-access-dev", "tfstate-identity-dev", "tfstate-identity-data-dev",
    "tfstate-identity-vault-dev", "tfstate-identity-messaging-dev",
    "tfstate-resource-groups-dev", "tfstate-platform-dev", "tfstate-access-dev",
    "tfstate-pulse-dev", "tfstate-notify-dev", "tfstate-automation-dev",
    "tfstate-monitoring-dev", "tfstate-deployment-access-dev", "tfstate-customer-directory-dev",
  ])
  tags = {
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:env"         = "dev"
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:adr"         = "ADR-0077"
  }
}

resource "azurerm_resource_group" "state" {
  name     = "rg-hd-tfstate-dev"
  location = "eastus2"
  tags     = local.tags
  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_account" "state" {
  name                            = "sthdtfstatedev"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access           = "Enabled"
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
    # Azure Storage represents a single /32 as the bare IPv4 address.
    ip_rules = [var.operator_ipv4]
  }
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
  tags = local.tags
  lifecycle { prevent_destroy = true }
}

# AzureRM 5 uses the management API with storage_account_id: no account-key
# bootstrap and no account-wide Blob grant is needed to create containers.
resource "azurerm_storage_container" "state" {
  for_each              = local.containers
  name                  = each.key
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
  lifecycle { prevent_destroy = true }
}

resource "azurerm_role_assignment" "operator" {
  for_each             = local.containers
  scope                = azurerm_storage_container.state[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.operator_object_id
  principal_type       = "User"
}

resource "azurerm_storage_management_policy" "history" {
  storage_account_id = azurerm_storage_account.state.id
  rule {
    name    = "expire-previous-state-versions"
    enabled = true
    filters { blob_types = ["blockBlob"] }
    actions {
      # No base_blob action: the current state is never expired.
      version { delete_after_days_since_creation = 90 }
    }
  }
}

resource "azurerm_management_lock" "state" {
  name       = "protect-terraform-state"
  scope      = azurerm_resource_group.state.id
  lock_level = "CanNotDelete"
  notes      = "Independent backend lifetime; removal requires a separately reviewed recovery operation."
  depends_on = [azurerm_storage_container.state, azurerm_role_assignment.operator, azurerm_storage_management_policy.history]
  lifecycle { prevent_destroy = true }
}
