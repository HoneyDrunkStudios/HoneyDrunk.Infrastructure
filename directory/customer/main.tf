# The live CIAM name includes its domain suffix, exceeding AzAPI embedded validation.
# Disable that local validator while preserving its imported metadata; never PATCH
# the directory merely to change provider validation metadata. The body stays managed.
resource "azapi_resource" "honeydrunkcustomers_onmicrosoft_com" {
  body = {
    "properties" = {
      "createTenantProperties" = {
        "countryCode" = "US"
        "displayName" = "HoneyDrunk Customers"
      }
      "tenantId" = "28ad6dfb-254d-41c3-a840-9b2135ed11a6"
    }
    "sku" = {
      "name" = "Base"
      "tier" = "A0"
    }
  }
  create_headers                   = null
  create_query_parameters          = null
  delete_headers                   = null
  delete_query_parameters          = null
  ignore_body_changes              = null
  ignore_casing                    = false
  ignore_missing_property          = true
  ignore_null_property             = false
  ignore_other_items_in_list       = null
  list_unique_id_property          = null
  location                         = "unitedstates"
  locks                            = null
  name                             = "honeydrunkcustomers.onmicrosoft.com"
  parent_id                        = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-identity-dev"
  read_headers                     = null
  read_query_parameters            = null
  replace_triggers_external_values = null
  replace_triggers_refs            = null
  response_export_values           = null
  retry                            = null
  schema_validation_enabled        = false
  sensitive_body                   = null
  sensitive_body_version           = null
  type                             = "Microsoft.AzureActiveDirectory/ciamDirectories@2023-05-17-preview"
  update_headers                   = null
  update_query_parameters          = null
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [schema_validation_enabled]
  }
}
