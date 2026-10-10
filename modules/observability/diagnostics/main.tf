resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-to-law"
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.workspace_id
  dynamic "enabled_log" {
    for_each = var.log_categories
    content { category = enabled_log.value }
  }
  enabled_metric { category = "AllMetrics" }
}
