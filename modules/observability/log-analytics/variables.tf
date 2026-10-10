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
