resource "azurerm_resource_group" "rg_hd_automation_dev" {
  location   = "eastus2"
  managed_by = null
  name       = "rg-hd-automation-dev"
  tags = {
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "azureapp_auto_alerts_98c8b5_oleg_honeydrunkstudios_com" {
  location   = "eastus"
  managed_by = null
  name       = "azureapp-auto-alerts-98c8b5-oleg_honeydrunkstudios_com"
  tags = {
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "rg_hd_identity_dev" {
  location   = "eastus2"
  managed_by = null
  name       = "rg-hd-identity-dev"
  tags = {
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "rg_hd_notify_dev" {
  location   = "eastus2"
  managed_by = null
  name       = "rg-hd-notify-dev"
  tags = {
    "env"  = "dev"
    "node" = "notify"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "rg_hd_platform_dev" {
  location   = "eastus2"
  managed_by = null
  name       = "rg-hd-platform-dev"
  tags = {
    "env"     = "dev"
    "purpose" = "platform-shared"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "rg_hd_pulse_dev" {
  location   = "eastus2"
  managed_by = null
  name       = "rg-hd-pulse-dev"
  tags = {
    "env"  = "dev"
    "node" = "pulse"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "defaultresourcegroup_eus2" {
  location   = "eastus2"
  managed_by = null
  name       = "DefaultResourceGroup-EUS2"
  tags = {
  }
  lifecycle {
    prevent_destroy = true
  }
}
