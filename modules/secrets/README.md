# modules/secrets

Per-concern Bicep modules for **secrets** (ADR-0077 D2).

**Owns:** Key Vault, Key Vault secrets-as-resources, App Configuration stores.

**Example resources:** `keyVault`, `keyVaultSecret`, `appConfigurationStore`.

**Status:** first module set authored (ADR-0077 packet 13). `keyVault` and
`appConfigurationStore` are part of the first set — every Node provisions a
per-Node Vault (invariant 17 / ADR-0005).

> **Secrets by URI, never by value** (ADR-0077 D7 / invariant 91). No module
> takes a raw secret value param. A `keyVaultSecret` module declares the secret
> *resource*, not its value; templates and `.bicepparam` files never carry
> secret values. Where a secret is conceptually needed, pass a Key Vault secret
> **URI string** (a non-secret reference), never a `@secure()` value carrying
> the secret itself.

**Consumed by** local relative path — no registry, no `br:` references (see the
[repo README](../../README.md)).

---

## `keyVault.bicep`

`Microsoft.KeyVault/vaults@2024-11-01`. Produces `kv-hd-<service>-<env>`
(invariant 17) with **Azure RBAC authorization enabled** and **no access
policies** (`accessPolicies: []`) (invariant 17). `standard` sku,
`tenantId: subscription().tenantId`, `enableSoftDelete: true`. A child
`Microsoft.Insights/diagnosticSettings@2021-05-01-preview` resource scoped to
the vault routes `AuditEvent` logs + `AllMetrics` to the shared Log Analytics
workspace (invariant 22) — the workspace is consumed by ID, **not** created.

> **Name length:** Key Vault names are ≤ 24 chars. `kv-hd-` (6) + a 13-char
> `service` + `-staging` (8) = 27, which exceeds 24. `@maxLength(13)` is the
> only enforcement here; **long service names must pass a shorter `service` at
> the call site** for the `staging`/`prod` environments.

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(13)`; feeds `kv-hd-<service>-<env>`. See name-length note. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags; applied to every resource. |
| `logAnalyticsWorkspaceId` | string | — | Shared workspace ID for diagnostics (invariant 22). Not created here. |
| `softDeleteRetentionInDays` | int | `90` | 7–90. |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `vaultUri` | string | Data-plane URI. |
| `vaultId` | string | Resource ID — scope RBAC / reference secrets by URI. |
| `name` | string | Resource name. |

### Reference example

```bicep
module vault '../../modules/secrets/keyVault.bicep' = {
  name: 'identityVault'
  params: {
    service: 'identity'
    env: env
    tags: tags
    logAnalyticsWorkspaceId: lawId        // from platform/
  }
}
```

---

## `appConfigurationStore.bicep`

`Microsoft.AppConfiguration/configurationStores@2024-06-01`. Produces
`appcs-hd-<service>-<env>`, `standard` sku.

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(13)`; feeds `appcs-hd-<service>-<env>`. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags; applied to every resource. |
| `sku` | string | `'standard'` | `@allowed('free','standard')`. |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `endpoint` | string | Data-plane endpoint (`https://<name>.azconfig.io`). |
| `id` | string | Resource ID. |
| `name` | string | Resource name. |

### Reference example

```bicep
module appcs '../../modules/secrets/appConfigurationStore.bicep' = {
  name: 'identityAppConfig'
  params: {
    service: 'identity'
    env: env
    tags: tags
  }
}
```

### Secret discipline

App Configuration holds non-secret config. Secret-shaped values live in Key
Vault and are referenced from App Configuration by **URI** (Key Vault
references) — never stored as App Configuration key-values in the template.
