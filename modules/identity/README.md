# modules/identity

Per-concern Bicep modules for **identity** (ADR-0077 D2).

**Owns:** managed identities, role assignments, RBAC scopes.

**Example resources:** `userAssignedIdentity`, `roleAssignment`.

**Status:** empty-state. Module bodies land in ADR-0077 packet 13.

> **Deploy-identity rights.** Provisioning `Microsoft.Authorization/roleAssignments`
> requires the OIDC deploy identity to hold **User Access Administrator** (or
> RBAC Administrator) on the target scope — Contributor can create resources but
> **cannot** create role assignments. Grant this before the first template that
> carries a `roleAssignment` is applied (e.g. the `platform/` layer and the
> per-Node leaf templates that wire AcrPull / Key Vault / App Configuration
> Data Reader).

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module acrPull '../../modules/identity/roleAssignment.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
