variable "bootstrap_operator_object_id" {
  description = "Temporary certificate installation access; null removes only this new bootstrap grant."
  type        = string
  default     = null
}
resource "azurerm_role_assignment" "certificate_installation" {
  for_each             = var.bootstrap_operator_object_id == null ? {} : { operator = var.bootstrap_operator_object_id }
  scope                = module.vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
  principal_type       = "User"
}
