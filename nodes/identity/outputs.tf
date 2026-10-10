output "principal_id" {
  description = "App MI; SQL contained-user and Azure grants require separate approval."
  value       = module.app.principal_id
}
output "hostname" {
  description = "Azure-returned hostname; not a claim of a serving API."
  value       = module.app.hostname
}
