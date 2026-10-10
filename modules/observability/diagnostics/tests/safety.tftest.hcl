# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  target_resource_id = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.KeyVault/vaults/kv-hd-identity-dev"
  workspace_id       = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.OperationalInsights/workspaces/log-hd-shared-dev"
  log_categories     = ["AuditEvent"]
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_monitor_diagnostic_setting.this.log_analytics_workspace_id == var.workspace_id && length(azurerm_monitor_diagnostic_setting.this.enabled_log) == 1
    error_message = "Audit diagnostics must reach the shared workspace."
  }
}
