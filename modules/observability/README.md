# Observability modules

AzureRM modules: log-analytics, application-insights and diagnostics. Share the workspace by ID; never output instrumentation/access keys.

Each module declares provider/version constraints, typed inputs and non-secret
outputs where needed. Run its `tests/safety.tftest.hcl` with a mocked provider.
Use only through a reviewed root with the shared provider lock and approved state.
See [migration boundaries](../../docs/terraform-migration.md) and the root README.
