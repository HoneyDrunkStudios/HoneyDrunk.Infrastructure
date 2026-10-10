# Synthetic IDs/CIDRs only. Every provider is mocked; no Azure login/backend.
mock_provider "azurerm" {
  mock_data "azurerm_container_app" {
    defaults = {
      identity = [{ type = "SystemAssigned", principal_id = "00000000-0000-4000-8000-000000000003", tenant_id = "00000000-0000-4000-8000-000000000002" }]
    }
  }
}
variables {
  name      = "example-hd-dev"
  server_id = "/subscriptions/00000000-0000-4000-8000-000000000001/resourceGroups/rg-hd-platform-dev/providers/Microsoft.Sql/servers/sql-hd-shared-dev"
  tags      = { "hd:node" : "honeydrunk-infrastructure", "hd:env" : "dev", "hd:owner" : "honeydrunkstudios", "hd:cost-center" : "core-infra", "hd:dr-tier" : "T1", "hd:adr" : "ADR-0077" }
}
run "safe_development_contract" {
  command = plan
  assert {
    condition     = azurerm_mssql_database.this.sku_name == "Basic" && azurerm_mssql_database.this.max_size_gb == 2 && azurerm_mssql_database.this.storage_account_type == "Local"
    error_message = "Database cost profile must remain Basic 2 GiB with local backups."
  }
  assert {
    condition     = azurerm_mssql_database.this.short_term_retention_policy[0].retention_days == 7
    error_message = "Seven-day retention must be explicit."
  }
}
