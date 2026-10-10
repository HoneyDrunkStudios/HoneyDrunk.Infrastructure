output "id" {
  description = "Id."
  value       = azurerm_key_vault.this.id
}
output "uri" {
  description = "Uri."
  value       = azurerm_key_vault.this.vault_uri
}
