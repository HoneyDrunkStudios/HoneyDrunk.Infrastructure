# A reviewed maintenance window may add exactly one workstation address. Null
# removes only this temporary rule; it does not toggle any durable resource.
variable "operator_ipv4" {
  type        = string
  default     = null
  description = "Temporary approved schema-window public IPv4; reset to null after the window."
  validation {
    condition     = var.operator_ipv4 == null ? true : can(cidrnetmask("${var.operator_ipv4}/32")) && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.operator_ipv4)) && var.operator_ipv4 != "0.0.0.0"
    error_message = "Only one IPv4 address is permitted; never a range or Azure-services bypass."
  }
}
resource "azurerm_mssql_firewall_rule" "operator" {
  for_each         = var.operator_ipv4 == null ? {} : { "nov-schema-window" = var.operator_ipv4 }
  name             = each.key
  server_id        = var.server_id
  start_ip_address = each.value
  end_ip_address   = each.value
}
