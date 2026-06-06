# modules/data

Per-concern Bicep modules for **data** (ADR-0077 D2).

**Owns:** SQL servers, SQL databases, Postgres servers, Cosmos accounts, Storage
accounts, Azure Cache for Redis.

**Example resources:** `sqlServer`, `sqlDatabase`, `postgresServer`,
`storageAccount`, `redisCache`.

**Status:** empty-state. The initial six-concern set (ADR-0077 packet 13) ships
`storageAccount`. `redisCache` (ADR-0076) lands when the Cache Node standup
(ADR-0059) is scoped and the resource shape is concrete; other data modules land
when a consumer first needs them.

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module storage '../../modules/data/storageAccount.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
