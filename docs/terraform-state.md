# State and authentication design

No backend resources/access have been created. Empty `backend "azurerm" {}`
blocks require operator configuration; CI disables backend initialization.
Provider installation is not evidence of adopted state.

## Bootstrap proposal

Approve a dedicated state resource group, globally unique StorageV2 account,
region/replication and cost. Its lifecycle must be independent of application
states so they cannot destroy their own backend. Do not repurpose Notify storage.

Require Azure Blob encryption, TLS 1.2+, HTTPS only, private containers, disabled
shared-key/anonymous access, versioning, blob/container soft delete and approved
retention/recovery. Prefer an approved private endpoint and runner network; these
have access/cost implications and are not silently provisioned. A restricted public
endpoint instead needs approved exact operator/runner paths. Never allow all public
networks or assume GitHub-hosted runners reach a private account. No key/SAS fallback.

Bootstrap in a separately approved operator session or dedicated bootstrap root
with protected temporary local state. Record/adopt backend resources into separate
state, then handle local sensitive copies under the retention policy. Confirm Blob
data-plane access and restore capability before adopting application resources.
These are design steps, not an automatic provisioning script.

Use Entra data-plane auth (`use_azuread_auth = true`) and approved GitHub OIDC
(`use_oidc = true`) for future CI. Preserve client/tenant/subscription IDs as
non-secret environment configuration. Restrict federation to the exact repo,
protected Environment and audience. No client secret/account key and no blanket
subscription Contributor/Owner. Local operators use approved Entra sessions with
explicit tenant/subscription; never copy tokens into backend configuration.

State permission is distinct from resource permission. Scope the approved
identity's Blob access (normally Storage Blob Data Contributor for leases/writes)
to the selected container, plus only required Azure management scopes. A state
reader sees the entire snapshot. Use separate containers/accounts where RBAC
isolation is needed; blob key names are not an access boundary. Federation, RBAC,
network changes and sensitive-inventory entries need separate approval.

## Per-root configuration

Use unique keys: `dev/platform.tfstate`, `dev/platform-app-network.tfstate`,
`dev/platform-sql.tfstate`, `dev/platform-sql-access.tfstate`,
`dev/identity.tfstate`, `dev/identity-data.tfstate`, `dev/identity-vault.tfstate`,
`dev/identity-messaging.tfstate`, `dev/pulse-access.tfstate`. Use explicit roots
and keys rather than workspaces that silently switch environments.

Non-executable example (not verified names):

```hcl
storage_account_name = "<approved-state-account>"
container_name       = "<approved-private-container>"
key                  = "dev/platform.tfstate"
use_azuread_auth      = true
use_oidc             = true
```

Configure `ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` through the
approved environment. Backend/provider authentication are independent. AzureRM
auto-registration is disabled (`resource_provider_registrations = "none"`);
missing registrations are an approval step, not permission to broaden access.

## Locking, confidentiality and recovery

The [AzureRM backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
uses Blob leases for native locking. Keep locking enabled and use a bounded lock
timeout. Future CI also serializes by state key and must not cancel active applies.
Identify/stop a failed writer before any separately approved stale-lock recovery.

Treat state/backups, saved plans/JSON, crash logs and backend metadata as sensitive.
AzureRM may read computed keys or app settings into state despite no secret
inputs/outputs. `sensitive` hides display, not stored values. No live plan/state
may reach PR comments, unrestricted artifacts/caches/logs or transcripts. Avoid
`TF_LOG` in authenticated sessions. PR tests are synthetic and mocked only.

After partial apply, stop writers and inspect Azure/state privately. Preserve the
latest state version/serial and failure evidence. Never overwrite a newer writer
with an old blob; state restoration does not roll back Azure. Review recovery or
re-import and a fresh confidential plan. Rehearse restore in an isolated approved
scope before production adoption. Version history is not automatic rollback.

See [sensitive state](https://developer.hashicorp.com/terraform/language/state/sensitive-data),
[provider mocking](https://developer.hashicorp.com/terraform/language/tests/mocking)
and [Azure Storage state guidance](https://learn.microsoft.com/azure/developer/terraform/store-state-in-azure-storage).
