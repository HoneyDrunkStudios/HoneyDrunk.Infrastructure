# The new runtime grants are owned only by this Identity root.
resource "azurerm_role_assignment" "registry_pull" {
  scope                            = "/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-platform-${var.environment}/providers/Microsoft.ContainerRegistry/registries/acrhdshared${var.environment}"
  role_definition_name             = "AcrPull"
  principal_id                     = module.app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
resource "azurerm_role_assignment" "vault_read" {
  scope                            = "/subscriptions/${var.subscription_id}/resourceGroups/rg-hd-identity-${var.environment}/providers/Microsoft.KeyVault/vaults/kv-hd-identity-${var.environment}"
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = module.app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
