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
Configuration Data Reader on the `rg-hd-platform-<env>` ACR + App Config). For an
in-RG, resource-scoped grant (e.g. Key Vault Secrets User on the Node's own
vault) assign inline in the leaf instead.

The assignment name is `guid(resourceGroup().id, principalId, roleDefinitionId,
nameSeed)` — deterministic, so re-deploys are idempotent. `principalType`
defaults to `ServicePrincipal` and is set explicitly so ARM tolerates a
freshly-created managed identity (avoids the AAD replication race).

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `principalId` | string | — | Object ID to grant to (e.g. a Container App system MI principalId). |
| `roleDefinitionId` | string | — | Bare built-in role GUID (e.g. AcrPull `7f951dda-…`). |
| `principalType` | string | `'ServicePrincipal'` | `@allowed('ServicePrincipal','User','Group')`. |
| `nameSeed` | string | — | Discriminator folded into the deterministic name. |

```bicep
module acrPull '../../modules/identity/roleAssignment.bicep' = {
  name: 'pulse-acrpull'
  scope: resourceGroup('rg-hd-platform-${env}')   // RG that holds the ACR
  params: {
    principalId: app.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'  // AcrPull
    nameSeed: 'pulse-acrpull'
  }
}
```
