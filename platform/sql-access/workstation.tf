# Persistent workstation access is separate from the temporary schema window.
# Import an existing rule by its exact name before narrowing its address range.
variable "workstation_access" {
  description = "Explicitly approved persistent workstation rule name and single public IPv4; null grants no workstation access."
  type = object({
    name = string
    ipv4 = string
  })
  default = null
  validation {
    condition = var.workstation_access == null ? true : (
      can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$", var.workstation_access.name)) &&
      lower(var.workstation_access.name) != "nov-schema-window" &&
      !startswith(lower(var.workstation_access.name), "identity-egress-") &&
      can(cidrnetmask("${var.workstation_access.ipv4}/32")) &&
      can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.workstation_access.ipv4)) &&
      var.workstation_access.ipv4 != "0.0.0.0"
    )
    error_message = "Workstation access requires a distinct rule name and one IPv4 address; maintenance/app rule names, ranges and the Azure-services bypass are forbidden."
  }
}

resource "azurerm_mssql_firewall_rule" "workstation" {
  for_each         = var.workstation_access == null ? {} : { (var.workstation_access.name) = var.workstation_access.ipv4 }
  name             = each.key
  server_id        = var.server_id
  start_ip_address = each.value
  end_ip_address   = each.value
}
