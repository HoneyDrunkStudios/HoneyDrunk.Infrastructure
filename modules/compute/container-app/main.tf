resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.environment_id
  revision_mode                = "Multiple"
  tags                         = var.tags
  identity { type = "SystemAssigned" }
  dynamic "secret" {
    for_each = var.secret_references
    content {
      name                = secret.key
      identity            = "System"
      key_vault_secret_id = secret.value
    }
  }
  dynamic "registry" {
    for_each = var.registry_servers
    content {
      server   = registry.value
      identity = "System"
    }
  }
  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.target_port
    transport                  = "auto"
    traffic_weight {
      latest_revision = false
      revision_suffix = var.serving_revision_suffix
      percentage      = 100
    }
  }
  template {
    revision_suffix = var.candidate_revision_suffix
    min_replicas    = 0
    max_replicas    = 10
    container {
      name   = var.container_name
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }
  }
  lifecycle { prevent_destroy = true }
}
