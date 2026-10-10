output "server_id" {
  description = "Shared server ID; each product owns a separate database."
  value       = module.server.id
}
