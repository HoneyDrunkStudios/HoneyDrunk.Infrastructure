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
  default     = "centralus"
  validation {
    condition     = var.location == "centralus"
    error_message = "The selected development hosting region is Central US."
  }
}

variable "subnet_id" {
  description = "No VNet integration for Central US hosting; preserve the existing East US 2 network."
  type        = string
  default     = null
  validation {
    condition     = var.subnet_id == null
    error_message = "Central US Identity uses scoped SQL firewall access without cross-region VNet integration."
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
