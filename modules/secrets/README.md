# modules/secrets

Per-concern Bicep modules for **secrets** (ADR-0077 D2).

**Owns:** Key Vault, Key Vault secrets-as-resources, App Configuration stores.

**Example resources:** `keyVault`, `keyVaultSecret`, `appConfigurationStore`.

**Status:** empty-state. Module bodies land in ADR-0077 packet 13 (the first
six-concern module set). `keyVault` is one of the first modules authored — every
Node provisions a per-Node Vault namespace (invariant 17 / ADR-0005).

> **Secrets by URI, never by value** (ADR-0077 D7 / invariant 91). A
> `keyVaultSecret` module declares the secret *resource*, not its value;
> templates and `.bicepparam` files never carry secret values.

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module vault '../../modules/secrets/keyVault.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
