// =============================================================================
// modules/observability/logAnalyticsWorkspace.bicep  (ADR-0077 packet 14)
// Microsoft.OperationalInsights/workspaces — the SHARED per-env Log Analytics
// workspace (log-hd-shared-{env}, invariant 22/35). One per environment, owned
// by the platform layer (NOT per-service): the `env`-only naming reflects that
// (there is no `service` param). Consumers (Key Vault diagnostics, App Insights,
// the Container Apps Environment) reference this workspace by its `id` output.
// The shared key is NEVER output (secret — D7 / invariant 91).
// =============================================================================

@description('Target environment.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param env string

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required Grid tags: hd:node, hd:env, hd:owner, hd:cost-center, hd:dr-tier, hd:adr. The consumer composes these once and passes them in.')
param tags object

@description('Workspace data retention in days (30-730). 30 is the Grid default.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

var name = 'log-hd-shared-${env}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

@description('The Log Analytics workspace resource ID — the canonical reference for diagnostics, App Insights, and the Container Apps Environment.')
output id string = workspace.id

@description('The Log Analytics workspace resource name.')
output name string = workspace.name

@description('The workspace customer (workspace) ID — a non-secret correlation identifier. The shared KEY is never output (secret — D7).')
output customerId string = workspace.properties.customerId
