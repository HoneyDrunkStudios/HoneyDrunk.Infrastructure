locals {
  tags = {
    "hd:node"        = "honeydrunk-infrastructure"
    "hd:env"         = var.environment
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "core-infra"
    "hd:dr-tier"     = "T1"
    "hd:adr"         = "ADR-0077"
  }
  platform_group = "rg-hd-platform-${var.environment}"
  # Azure can return a trailing comma, represented by the provider as an empty
  # list element. Discard only blank elements; malformed nonblank IPs still fail.
  identity_outbound_ipv4 = toset(compact([for ip in data.azurerm_linux_web_app.identity.outbound_ip_address_list : trimspace(ip)]))
}

data "azurerm_linux_web_app" "identity" {
  name                = var.app_name
  resource_group_name = "rg-hd-identity-${var.environment}"
  lifecycle {
    postcondition {
      condition     = self.location == "centralus" && length(compact([for ip in self.outbound_ip_address_list : trimspace(ip)])) > 0
      error_message = "Resolve the existing Central US Identity app and its current outbound addresses before granting SQL access."
    }
  }
}

# The approved public-egress design preserves the existing East US 2 VNet.
# Read current addresses from the one approved app; never allow all Azure services or ranges.
resource "azurerm_mssql_firewall_rule" "identity_egress" {
  for_each         = local.identity_outbound_ipv4
  name             = "identity-egress-${replace(each.value, ".", "-")}"
  server_id        = var.server_id
  start_ip_address = each.value
  end_ip_address   = each.value
  lifecycle {
    precondition {
      condition     = can(cidrnetmask("${each.value}/32")) && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", each.value)) && each.value != "0.0.0.0"
      error_message = "Runtime firewall rules must be individual IPv4 addresses, never an Azure-services bypass."
    }
  }
}

output "identity_outbound_ipv4" {
  description = "Current app outbound addresses covered by individual SQL firewall rules; re-plan after hosting changes."
  value       = sort(tolist(local.identity_outbound_ipv4))
}
