# Compute modules

AzureRM modules: app-service-plan, app-service, container-app-environment and container-app. App Service starts stopped; the Pulse root never instantiates a managed Container App.

Each module declares provider/version constraints, typed inputs and non-secret
outputs where needed. Run its `tests/safety.tftest.hcl` with a mocked provider.
Use only through a reviewed root with the shared provider lock and approved state.
See [migration boundaries](../../docs/terraform-migration.md) and the root README.
