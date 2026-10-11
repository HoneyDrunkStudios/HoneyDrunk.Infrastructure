# Required to inspect/request the single approved B1 instance through Azure's
# quota API. Registration itself grants no instance quota and creates no VM.
resource "azurerm_resource_provider_registration" "quota" {
  name = "Microsoft.Quota"
  lifecycle { prevent_destroy = true }
}
