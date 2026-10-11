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
    error_message = "The approved development SQL server is in Central US; other services remain in East US 2."
  }
}

variable "administrator_name" {
  description = "Administrator name."
  type        = string
}

variable "administrator_object_id" {
  description = "Existing administrator object ID, or null when creating the administrator group."
  type        = string
  default     = null
}
