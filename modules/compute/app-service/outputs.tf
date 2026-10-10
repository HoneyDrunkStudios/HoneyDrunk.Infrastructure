output "id" {
  description = "Id."
  value       = azurerm_linux_web_app.this.id
}
output "principal_id" {
  description = "Principal id."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
output "hostname" {
  description = "Hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}
