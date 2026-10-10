output "subnet_id" {
  description = "Subnet with App Service delegation and Microsoft.Sql service endpoint."
  value       = module.network.subnet_id
}
