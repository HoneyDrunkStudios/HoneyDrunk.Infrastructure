variable "target_resource_id" {
  description = "Target resource id."
  type        = string
}

variable "workspace_id" {
  description = "Workspace id."
  type        = string
}

variable "log_categories" {
  description = "Log categories."
  type        = set(string)
}
