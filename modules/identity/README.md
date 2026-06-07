# modules/identity

Per-concern Bicep modules for **identity** (ADR-0077 D2).

**Owns:** managed identities, role assignments, RBAC scopes.

**Example resources:** `userAssignedIdentity`, `roleAssignment`.

**Status:** `roleAssignment.bicep` authored (ADR-0077, first Node leaf). The
generic, idempotent role-assignment module the per-Node leaf templates use to
grant their Container App identity access to shared resources.

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

---

## `roleAssignment.bicep`

`Microsoft.Authorization/roleAssignments@2022-04-01`. A generic,
**resource-group-scoped** role assignment. Deploy it with a `scope:
resourceGroup('rg-...')` from the caller to place the grant in the RG that holds
the target resource — this is how a Node leaf grants its Container App identity
access to **shared** resources in a *different* RG (e.g. AcrPull / App
Configuration Data Reader on the `rg-hd-platform-<env>` ACR + App Config). Omit
`scope` to grant in the leaf's own RG (e.g. Key Vault Secrets User on the Node's
own vault).

A module can only scope to a resourceGroup, not a single resource (**BCP134**),
so grants sit at RG scope. That is not a privilege concern: the built-in roles
used are resource-**type** scoped and each target RG is single-purpose (the
platform RG holds only shared resources; a Node RG only that Node's), so an
RG-scoped grant of a type-scoped role is effectively resource-scoped.

The name is `guid(resourceGroup().id, principalId, roleDefinitionId)` — it folds
in the **principalId**. Computing it inside this nested module sidesteps the
BCP120 "name must be known at start" rule (which fires if you build a role
assignment name from a module output in the parent), and means a
delete-and-recreate of the app (new MI → new principalId) yields a NEW assignment
rather than an illegal update of the immutable `principalId` on the old one.
`principalType` is set explicitly so ARM tolerates a freshly-created MI (avoids
the AAD replication race).

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `principalId` | string | — | Object ID to grant to (e.g. a Container App system MI principalId). |
| `roleDefinitionId` | string | — | Bare built-in role GUID (e.g. AcrPull `7f951dda-…`). |
| `principalType` | string | `'ServicePrincipal'` | `@allowed('ServicePrincipal','User','Group')`. |

```bicep
module acrPull '../../modules/identity/roleAssignment.bicep' = {
  name: 'pulse-acrpull'
  scope: resourceGroup('rg-hd-platform-${env}')   // RG that holds the ACR
  params: {
    principalId: app.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'  // AcrPull
  }
}
```
