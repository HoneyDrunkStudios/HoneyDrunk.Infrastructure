output "id" {
  description = "Id."
  value       = azurerm_container_app.this.id
}
output "principal_id" {
  description = "Principal id."
  value       = azurerm_container_app.this.identity[0].principal_id
}
