# Changelog

All notable changes to the HoneyDrunk.Infrastructure Bicep-content surface are
recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- `platform/main.bicep`: parameterized the container-registry and App Configuration **SKUs** (`containerRegistrySku`, `appConfigurationSku`). The first dev what-if showed the existing `acrhdshareddev` (Basic) and `appcs-hd-shared-dev` (developer) would be *upgraded* to Standard by the module defaults; dev now sets `Basic` / `developer` to match, so the import is a tag-only no-op rather than a SKU change. `modules/secrets/appConfigurationStore.bicep` `sku` `@allowed` widened to `free` / `developer` / `standard` / `premium`.
- `deploy.yml`: added a **`mode` input (`plan` / `apply`, default `plan`)**. `plan` runs a what-if dry run only (nothing applied); `apply` deploys. Passed through to the Actions `job-deploy-bicep.yml` as `what-if-only`, so a first run can be reviewed (confirm existing dev resources show as no-change) before touching anything. **Requires the Actions PR adding `what-if-only` to merge first.**
- `modules/data/storageAccount.bicep`: set `allowSharedKeyAccess: false` — account-key/shared-key auth disabled, Entra (Managed Identity) + RBAC only, matching the no-local-auth posture (KV RBAC-only, App Config `disableLocalAuth`).

### Added

- Platform shared-foundation layer + deploy caller (ADR-0077 packet 14):
  `platform/main.bicep` composes the per-env shared foundation into
  `rg-hd-platform-{env}` — Log Analytics (`log-hd-shared-{env}`,
  `Microsoft.OperationalInsights/workspaces@2025-07-01`, `PerGB2018`), the
  Container Apps Environment (`cae-hd-{env}`,
  `Microsoft.App/managedEnvironments@2025-07-01`), the container-image ACR
  (`acrhdshared{env}`, `Microsoft.ContainerRegistry/registries@2025-11-01`,
  `adminUserEnabled: false`, invariant 35), and the shared Service Bus
  (`sb-hd-shared-{env}`, reusing the packet-13 `serviceBusNamespace.bicep` with
  `service: 'shared'`) — and **exports their resource IDs**
  (`logAnalyticsWorkspaceId`, `containerAppEnvironmentId`, `containerRegistryId`,
  `containerRegistryLoginServer`, `serviceBusNamespaceId`) as the canonical
  reference for per-Node leaf templates (closes the hand-pasted-ARM-ID gap).
  Three new platform modules — `observability/logAnalyticsWorkspace.bicep`,
  `compute/containerAppEnvironment.bicep`, `data/containerRegistry.bicep`. The
  Container Apps Environment routes logs via the `azure-monitor` destination +
  a child `Microsoft.Insights/diagnosticSettings@2021-05-01-preview` referencing
  the workspace by ID — NO Log Analytics `sharedKey` in the template (D7). Per-env
  `platform/parameters.{dev,staging,prod}.bicepparam`, tagged
  `hd:node=honeydrunk-infrastructure` / `hd:cost-center=core-infra`. Existing
  `dev` resources grandfather via `what-if` no-op import (D6). Adds
  `.github/workflows/deploy.yml` — the `workflow_dispatch` caller that resolves
  template/params/RG by `target` (`platform`|`node`) + `env` and invokes the
  Actions `job-deploy-bicep.yml@main` behind the ADR-0033 environment approval
  gate (OIDC creds from repo/org vars). `platform/README.md` documents the
  shared-foundation resources, the `rg-hd-platform-{env}` /
  `rg-hd-platform-shared` RG model, the D6 grandfather/import posture, and the
  exported-ID convention.
- First per-concern Bicep module set (ADR-0077 packet 13): six reusable modules
  consumed by local relative path (no registry) —
  `compute/containerApp.bicep` (`Microsoft.App/containerApps@2025-07-01`;
  `ca-hd-<service>-<env>`, system-assigned MI, Multiple revision mode,
  consumes the shared Container Apps Environment by ID — invariants 34/36),
  `secrets/keyVault.bicep` (`Microsoft.KeyVault/vaults@2024-11-01`;
  `kv-hd-<service>-<env>`, Azure RBAC, no access policies, `AuditEvent` +
  `AllMetrics` diagnostics to the shared Log Analytics workspace via
  `Microsoft.Insights/diagnosticSettings@2021-05-01-preview` — invariants 17/22),
  `secrets/appConfigurationStore.bicep`
  (`Microsoft.AppConfiguration/configurationStores@2024-06-01`; the single
  shared `appcs-hd-shared-<env>` store per ADR-0005, MI-only / local auth
  disabled, provisioned by `platform/`),
  `data/storageAccount.bicep` (`Microsoft.Storage/storageAccounts@2024-01-01`;
  hyphen-free `sthd<service><env>`, StorageV2, TLS1_2, blob public access off),
  `messaging/serviceBusNamespace.bicep`
  (`Microsoft.ServiceBus/namespaces@2024-01-01`; `sb-hd-<service>-<env>`), and
  `observability/applicationInsights.bicep`
  (`Microsoft.Insights/components@2020-02-02`; workspace-based
  `appi-hd-<service>-<env>`, consumes the shared Log Analytics workspace by ID).
  Each applies the D3 tags/naming conventions (`@maxLength(13)` per invariant 19,
  or `@maxLength(11)` for the hyphen-free storage name) and D7 secret discipline
  (no raw secret params; Vault-URI references). Shared resources
  (`containerAppEnvironmentId`, `logAnalyticsWorkspaceId`) are consumed by ID,
  not created. Concern READMEs (`compute`, `secrets`, `data`, `messaging`,
  `observability`) document params/outputs and local-path reference examples.
- Repo scaffold (ADR-0077 packet 11): `modules/` (seven per-concern subdirectories
  with READMEs), `platform/`, and `nodes/` tree; single root `bicepconfig.json`
  carrying the ADR-0077 D3 naming/tagging + secret-hygiene linter rules across all
  three subtrees; repo `README.md` and this `CHANGELOG.md`; `.honeydrunk-review.yaml`
  (`enabled: true`); `.github/workflows/pr.yml` consuming the
  `HoneyDrunk.Actions` `job-bicep-lint.yml` gate (the Bicep-native `core` check)
  plus `job-secret-scan.yml`; and `.github/workflows/pr-review.yml` (the ADR-0086
  Grid review trigger). Module references are local relative path — no registry,
  no `br:` references.
