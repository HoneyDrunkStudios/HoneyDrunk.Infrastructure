mock_provider "azapi" {}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = azapi_resource.honeydrunkcustomers_onmicrosoft_com.body.properties.tenantId == "28ad6dfb-254d-41c3-a840-9b2135ed11a6"
    error_message = "Existing deployment behavior or recovery access must be preserved."
  }
}
