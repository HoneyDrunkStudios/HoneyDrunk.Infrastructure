// =============================================================================
// modules/identity/roleAssignment.bicep  (ADR-0077)
// A generic, resource-group-scoped Azure RBAC role assignment. Deploy it WITH a
// `scope: resourceGroup('rg-...')` from the caller to place the grant in the
// resource group that holds the target resource — this is how a Node leaf grants
// its Container App identity access to SHARED resources that live in a DIFFERENT
// resource group (e.g. the platform ACR / App Configuration in
// rg-hd-platform-<env>). The deploy identity needs User Access Administrator on
// that resource group (bootstrap grant, out-of-band) for this to apply.
//
// Scope note: a Bicep *module* can only be scoped to a resourceGroup, not to a
// single resource (BCP134), so cross-RG grants land at RG scope. That is not a
// privilege concern here: the built-in roles used (AcrPull, App Configuration
// Data Reader, Key Vault Secrets User) are resource-TYPE scoped, and each target
// RG is single-purpose (the platform RG holds only shared resources; a Node RG
// holds only that Node's resources) — so an RG-scoped grant of a type-scoped role
// is effectively resource-scoped.
//
// The assignment name folds in the **principalId** — `guid(rg, principalId,
// roleDefinitionId)`. principalId can be a runtime value (a Container App's
// system-MI principalId, only known after the app deploys): because the name is
// computed HERE, inside a nested module where principalId is an ordinary param,
// it sidesteps the BCP120 "name must be known at start" rule that fires if you
// build the name from a module output in the parent template. Folding in the
// principal also means a delete-and-recreate of the app (new MI → new principalId)
// yields a NEW assignment name rather than an illegal update of the immutable
// principalId on the existing one. No secret values (D7 / invariant 91).
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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: principalType
  }
}

@description('The role assignment resource ID.')
output id string = roleAssignment.id
