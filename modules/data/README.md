# modules/data

Per-concern Bicep modules for **data** (ADR-0077 D2).

**Owns:** SQL servers, SQL databases, Postgres servers, Cosmos accounts, Storage
accounts, Azure Cache for Redis.

**Example resources:** `sqlServer`, `sqlDatabase`, `postgresServer`,
`storageAccount`, `redisCache`.

**Status:** first module set authored (ADR-0077 packet 13) ships
`storageAccount`. `redisCache` (ADR-0076) lands when the Cache Node standup
(ADR-0059) is scoped; other data modules land when a consumer first needs them.

**Consumed by** local relative path — no registry, no `br:` references (see the
[repo README](../../README.md)).

---

## `storageAccount.bicep`

`Microsoft.Storage/storageAccounts@2024-01-01`. `StorageV2`, `Standard_LRS`
(param-defaulted), with `minimumTlsVersion: 'TLS1_2'`,
`allowBlobPublicAccess: false`, `supportsHttpsTrafficOnly: true`.

> **Special naming.** Storage account names are 3–24 chars, **lowercase letters
> and digits only — no hyphens**. The module composes
> `var name = toLower('sthd<service><env>')` (hyphen-free). For this reason
> `service` is capped at `@maxLength(11)` (not 13) so the worst case
> `sthd`(4) + `service`(≤11) + `staging`(7) = 22 stays within the 24-char limit.

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(11)` (storage 24-char limit); feeds `sthd<service><env>`. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags; applied to every resource. |
| `sku` | string | `'Standard_LRS'` | `@allowed('Standard_LRS','Standard_ZRS','Standard_GRS')`. |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `id` | string | Resource ID. |
| `name` | string | Resource name. |
| `primaryBlobEndpoint` | string | `https://<name>.blob.core.windows.net/`. |

### Secret discipline (ADR-0077 D7 / invariant 91)

No raw secret params, and no account keys output. Consumers authenticate to the
account via **managed identity + RBAC**; account keys, if ever needed, live in
Key Vault and are referenced by URI — never templated or output.

### Reference example

```bicep
module storage '../../modules/data/storageAccount.bicep' = {
  name: 'notifyStorage'
  params: {
    service: 'notify'
    env: env
    tags: tags
  }
}
```
