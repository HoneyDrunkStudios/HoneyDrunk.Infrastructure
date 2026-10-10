variable "subscription_id" {
  description = "Explicit target subscription; tests use synthetic IDs."
  type        = string
}

variable "tenant_id" {
  description = "Workforce tenant for Azure resources, not the External ID tenant."
  type        = string
}

variable "environment" {
  description = "Environment."
  type        = string
  default     = "dev"
  validation {
    condition     = var.environment == "dev"
    error_message = "Only development composition is reviewed; staging/production require a separate design."
  }
}

variable "location" {
  description = "Location."
  type        = string
  default     = "eastus2"
  validation {
    condition     = var.location == "eastus2"
    error_message = "The selected development design is East US 2."
  }
}

variable "subnet_id" {
  description = "Subnet id."
  type        = string


  validation {
    condition     = lower(var.subnet_id) == lower("/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-platform-${var.environment}/providers/Microsoft.Network/virtualNetworks/vnet-hd-apps-${var.environment}/subnets/snet-app-service")
    error_message = "Use the convention-named shared development resource in the selected subscription."
  }
}

variable "app_name" {
  description = "Default proposed name; a reviewed suffix may resolve a global-name collision."
  type        = string
  default     = "app-hd-identity-dev"
  validation {
    condition     = can(regex("^app-hd-identity-dev(-[a-z0-9]{1,8})?$", var.app_name))
    error_message = "Preserve the Identity/dev name; only a reviewed collision suffix is supported."
  }
}
