variable "subscription_id" {
  type        = string
  description = "Explicit approved development subscription."
}
variable "tenant_id" {
  type        = string
  description = "Workforce tenant."
}
variable "operator_object_id" {
  type        = string
  description = "Existing human operator; receives only container-scoped Blob Data Contributor."
  validation {
    condition     = can(regex("^[a-fA-F0-9-]{36}$", var.operator_object_id))
    error_message = "Supply the existing operator object UUID."
  }
}
variable "operator_ipv4" {
  type        = string
  description = "Approved single public IPv4, without /32; never a CIDR/range."
  validation {
    condition     = can(cidrnetmask("${var.operator_ipv4}/32")) && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.operator_ipv4)) && !can(regex("^(0|10|127|169\\.254|192\\.168|172\\.(1[6-9]|2[0-9]|3[01]))\\.", var.operator_ipv4))
    error_message = "Use one public IPv4 address; private ranges, CIDRs and the Azure-services bypass are prohibited."
  }
}
