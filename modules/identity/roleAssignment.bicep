// =============================================================================
// modules/identity/roleAssignment.bicep  (ADR-0077)
// A generic, resource-group-scoped Azure RBAC role assignment. Deploy it WITH a
// `scope: resourceGroup('rg-...')` from the caller to place the assignment in the
// resource group that holds the target resource — this is how a Node leaf grants
// its Container App's system-assigned identity access to SHARED resources that
// live in a DIFFERENT resource group (e.g. the platform ACR / App Configuration
// in rg-hd-platform-<env>). The deploy identity needs User Access Administrator
// on that resource group (bootstrap grant, out-of-band) for this to apply.
//
// The assignment name is a deterministic guid() of (rg, principal, role, seed),
// so re-deploys are idempotent — the same grant resolves to the same name rather
// than creating a duplicate. No secret values (D7 / invariant 91).
// =============================================================================

@description('Object (principal) ID to grant the role to — e.g. a Container App system-assigned managed identity principalId.')
param principalId string

@description('Built-in role definition GUID (the bare GUID, not the full resource ID). e.g. AcrPull = 7f951dda-4ed3-4680-a7ca-43fe172d538d.')
param roleDefinitionId string

@description('Principal type. ServicePrincipal for managed identities — set explicitly so ARM skips the AAD existence check and tolerates a freshly created identity (avoids the replication race).')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

@description('Stable discriminator folded into the deterministic assignment name — distinguishes multiple grants of (potentially) the same role to the same principal in one resource group. e.g. \'pulse-acrpull\'.')
param nameSeed string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId, nameSeed)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: principalType
  }
}

@description('The role assignment resource ID.')
output id string = roleAssignment.id
