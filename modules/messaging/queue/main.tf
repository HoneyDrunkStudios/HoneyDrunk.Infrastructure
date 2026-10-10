resource "azurerm_servicebus_queue" "this" {
  name                                    = var.name
  namespace_id                            = var.namespace_id
  max_delivery_count                      = 10
  max_size_in_megabytes                   = 1024
  requires_duplicate_detection            = true
  duplicate_detection_history_time_window = "PT10M"
  partitioning_enabled                    = false
  batched_operations_enabled              = true
  lock_duration                           = "PT1M"
  default_message_ttl                     = "P14D"
  dead_lettering_on_message_expiration    = true
  lifecycle { prevent_destroy = true }
}
