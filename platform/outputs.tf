output "resource_ids" {
  description = "Non-secret references; distribute approved IDs without granting access to platform state."
  value = {
    log_analytics_workspace   = module.logs.id
    container_app_environment = module.environment.id
    registry                  = module.registry.id
    app_configuration         = module.configuration.id
    service_bus               = module.messaging.id
  }
}
