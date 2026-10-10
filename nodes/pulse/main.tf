locals {
  tags = {
    "hd:node"        = "honeydrunk-pulse"
    "hd:env"         = var.environment
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "observability"
    "hd:dr-tier"     = "T2"
    "hd:adr"         = "ADR-0077"
  }
  platform_group = "rg-hd-platform-${var.environment}"
}
# Read-only app reference: no Container App PUT, image replay, revision or traffic writes.
data "azurerm_container_app" "pulse" {
  name                = "ca-hd-pulse-${var.environment}"
  resource_group_name = "rg-hd-pulse-${var.environment}"
}
locals {
  roles = {
    acr_pull             = { role = "7f951dda-4ed3-4680-a7ca-43fe172d538d", group = local.platform_group }
    configuration_reader = { role = "516239f1-63e1-4d78-a4de-a74fb236a071", group = local.platform_group }
    vault_reader         = { role = "4633458b-17de-408a-b874-0445c86b69e6", group = "rg-hd-pulse-${var.environment}" }
  }
}

module "access" {
  for_each           = local.roles
  source             = "../../modules/identity/role-assignment"
  assignment_name    = var.existing_assignment_names[each.key]
  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.group}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${each.value.role}"
  principal_id       = data.azurerm_container_app.pulse.identity[0].principal_id
}
output "principal_id" {
  description = "Existing Pulse identity; no app mutation."
  value       = data.azurerm_container_app.pulse.identity[0].principal_id
}
