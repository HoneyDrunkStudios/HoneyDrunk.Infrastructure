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

variable "existing_assignment_names" {
  description = "Existing assignment names."
  type        = map(string)

  validation {
    condition     = toset(keys(var.existing_assignment_names)) == toset(["acr_pull", "configuration_reader", "vault_reader"]) && alltrue([for id in values(var.existing_assignment_names) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])
    error_message = "Supply exactly the three inventoried existing assignment UUIDs before adoption."
  }
}
