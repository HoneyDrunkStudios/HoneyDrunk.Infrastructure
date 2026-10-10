resource "azurerm_mssql_database" "this" {
  name                 = var.name
  server_id            = var.server_id
  tags                 = var.tags
  sku_name             = "Basic"
  max_size_gb          = 2
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  zone_redundant       = false
  storage_account_type = "Local"
  short_term_retention_policy { retention_days = 7 }
  lifecycle { prevent_destroy = true }
}
