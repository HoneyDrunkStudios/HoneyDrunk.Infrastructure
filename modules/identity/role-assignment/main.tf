resource "azurerm_role_assignment" "this" {
  # Pass the existing assignment UUID during adoption; never replace a Bicep GUID.
  name               = var.assignment_name
  scope              = var.scope
  principal_id       = var.principal_id
  role_definition_id = var.role_definition_id
  principal_type     = "ServicePrincipal"
  lifecycle { prevent_destroy = true }
}
