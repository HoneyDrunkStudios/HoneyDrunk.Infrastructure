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

variable "workspace_id" {
  description = "Workspace id."
  type        = string


  validation {
    condition     = lower(var.workspace_id) == lower("/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-platform-${var.environment}/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-${var.environment}")
    error_message = "Use the convention-named shared development resource in the selected subscription."
  }
}
