// =============================================================================
// modules/observability/applicationInsights.bicep  (ADR-0077 packet 13)
// Microsoft.Insights/components — workspace-based Application Insights, wired to
// the shared Log Analytics workspace (consumed by ID; NOT created here).
// No raw secret params (D7 / invariant 91).
// =============================================================================

@description('Service or Node short name; feeds the resource name.')
@maxLength(13)
param service string

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

@description('Resource ID of the shared Log Analytics workspace (provisioned by platform/, packet 14) that this Application Insights component ingests into. Required for workspace-based App Insights. This module does NOT create the workspace.')
param logAnalyticsWorkspaceId string

var name = 'appi-hd-${service}-${env}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// Per ADR-0040 / ADR-0077 D7, the Application Insights connection string and
// instrumentation key are Vault-held credentials and are intentionally NOT
// exposed as deployment outputs (outputs surface in `az deployment ... outputs`
// and CI logs). Consumers obtain the connection string via the Key Vault
// reference pattern (store it as a keyVaultSecret and inject by URI) or via
// Entra-based ingestion auth — never from a plain module output. The module
// exposes only the non-secret identifiers below.

@description('The Application Insights component resource ID.')
output id string = appInsights.id

@description('The Application Insights component resource name.')
output name string = appInsights.name
