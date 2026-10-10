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

variable "environment_id" {
  description = "Environment id."
  type        = string
}

variable "container_name" {
  description = "Container name."
  type        = string
}

variable "image" {
  description = "Approved immutable OCI image digest; never a historical release default."
  type        = string

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.image))
    error_message = "An immutable approved image digest is required."
  }
}

variable "candidate_revision_suffix" {
  description = "Candidate revision suffix."
  type        = string
}

variable "serving_revision_suffix" {
  description = "Serving revision suffix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.serving_revision_suffix)) && var.serving_revision_suffix != "latest"
    error_message = "Retain the verified named serving revision; never latest."
  }
}

variable "target_port" {
  description = "Target port."
  type        = number
  default     = 8080
}

variable "secret_references" {
  description = "Secret name to Key Vault URI; only the system identity resolves secret material."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for uri in values(var.secret_references) : can(regex("^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/secrets/[^/]+(/[^/]+)?$", uri))])
    error_message = "Secrets must be Key Vault URIs, never literal values."
  }
}

variable "registry_servers" {
  description = "Registry servers."
  type        = set(string)
  default     = []
}

variable "environment_variables" {
  description = "Non-secret runtime settings for an explicitly reviewed maintenance composition."
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Environment variable name to declared Key Vault secret reference name."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for name in values(var.secret_environment_variables) : contains(keys(var.secret_references), name)]) && length(setintersection(toset(keys(var.environment_variables)), toset(keys(var.secret_environment_variables)))) == 0
    error_message = "Secret environment names must be declared and cannot overlap literal environment variables."
  }
}
