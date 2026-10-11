resource "azurerm_key_vault" "kv_hd_automation_dev" {
  access_policy                   = []
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  location                        = "eastus2"
  name                            = "kv-hd-automation-dev"
  public_network_access_enabled   = true
  purge_protection_enabled        = false
  rbac_authorization_enabled      = true
  resource_group_name             = "rg-hd-automation-dev"
  sku_name                        = "standard"
  soft_delete_retention_days      = 90
  tags = {
    "env"     = "dev"
    "purpose" = "automation"
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
