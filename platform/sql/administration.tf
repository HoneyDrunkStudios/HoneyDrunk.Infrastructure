variable "create_administrator_group" {
  description = "Create the reviewed workforce SQL admin group in this root."
  type        = bool
  default     = false
}
variable "administrator_member_object_id" {
  description = "Workforce operator member and owner of the new SQL admin group."
  type        = string
  default     = null
}
resource "azuread_group" "sql_administrators" {
  count                   = var.create_administrator_group ? 1 : 0
  display_name            = var.administrator_name
  description             = "Development shared SQL bootstrap administrators; no customer identities."
  security_enabled        = true
  mail_enabled            = false
  mail_nickname           = "hd-sql-admins-dev"
  prevent_duplicate_names = true
  owners                  = [var.administrator_member_object_id]
  members                 = [var.administrator_member_object_id]
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.administrator_member_object_id != null
      error_message = "A verified workforce administrator member is required."
    }
  }
}
resource "azurerm_resource_provider_registration" "sql" {
  name = "Microsoft.Sql"
  lifecycle { prevent_destroy = true }
}
output "administrator_group_object_id" {
  value = var.create_administrator_group ? azuread_group.sql_administrators[0].object_id : var.administrator_object_id
}
