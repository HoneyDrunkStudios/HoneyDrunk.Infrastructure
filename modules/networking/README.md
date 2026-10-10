# Networking modules

AzureRM modules: app-service. Explicit reviewed IPv4 CIDRs, subnet containment, /27-or-larger integration subnet, Microsoft.Web delegation and Microsoft.Sql endpoint.

Each module declares provider/version constraints, typed inputs and non-secret
outputs where needed. Run its `tests/safety.tftest.hcl` with a mocked provider.
Use only through a reviewed root with the shared provider lock and approved state.
See [migration boundaries](../../docs/terraform-migration.md) and the root README.
