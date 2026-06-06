# Changelog

All notable changes to the HoneyDrunk.Infrastructure Bicep-content surface are
recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

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
  (`Microsoft.AppConfiguration/configurationStores@2024-06-01`;
  `appcs-hd-<service>-<env>`),
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
