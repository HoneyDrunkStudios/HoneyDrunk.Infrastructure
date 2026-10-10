variable "name" {
  description = "Convention-qualified Azure resource name; immutable after adoption."
  type        = string
}

variable "resource_group_name" {
  description = "Existing owning resource group; this module never creates it."
  type        = string
}

variable "location" {
  description = "Approved Azure region."
  type        = string
}

variable "tags" {
  description = "Required Grid ownership, environment, cost and decision tags."
  type        = map(string)
  validation {
    condition     = alltrue([for key in ["hd:node", "hd:env", "hd:owner", "hd:cost-center", "hd:dr-tier", "hd:adr"] : try(trimspace(var.tags[key]) != "", false)])
    error_message = "All six Grid ownership/cost/decision tags are required."
  }
}

variable "administrator_name" {
  description = "Administrator name."
  type        = string


  validation {
    condition     = trimspace(var.administrator_name) != ""
    error_message = "An approved workforce Entra group name is required."
  }
}

variable "administrator_object_id" {
  description = "Administrator object id."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.administrator_object_id))
    error_message = "Supply the approved workforce Entra administrator group object ID."
  }
}

variable "tenant_id" {
  description = "Tenant id."
  type        = string
}
