output "id" {
  description = "Id."
  value       = azurerm_mssql_server.this.id
}
output "fqdn" {
  description = "Fqdn."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}
