# Messaging modules

AzureRM modules: service-bus and queue. Preserve live namespace auth during adoption; queues retain duplicate detection and dead-letter policies.

Each module declares provider/version constraints, typed inputs and non-secret
outputs where needed. Run its `tests/safety.tftest.hcl` with a mocked provider.
Use only through a reviewed root with the shared provider lock and approved state.
See [migration boundaries](../../docs/terraform-migration.md) and the root README.
