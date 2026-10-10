output "id" {
  description = "Id."
  value       = azurerm_container_registry.this.id
}
output "login_server" {
  description = "Login server."
  value       = azurerm_container_registry.this.login_server
}
