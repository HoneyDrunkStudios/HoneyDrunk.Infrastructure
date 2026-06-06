# modules/compute

Per-concern Bicep modules for **compute** (ADR-0077 D2).

**Owns:** the Container Apps environment, Container Apps, Container Apps Jobs,
Function Apps.

**Example resources:** `containerAppEnvironment`, `containerApp`,
`containerAppJob`.

**Status:** empty-state. Module bodies land in ADR-0077 packet 13 (the first
six-concern module set). `containerApp` is one of the first modules authored —
every Node provisions a Container App.

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module app '../../modules/compute/containerApp.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
