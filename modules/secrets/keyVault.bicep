// =============================================================================
// modules/secrets/keyVault.bicep  (ADR-0077 packet 13)
// Microsoft.KeyVault/vaults — one Key Vault per Node per env (invariant 17).
// Azure RBAC authorization, NO access policies (invariant 17). Diagnostic
// settings route AuditEvent + AllMetrics to the shared Log Analytics workspace
// (invariant 22). Consumes the workspace by ID; does NOT create it. No raw
// secret params (D7 / invariant 91).
// =============================================================================

@description('Service or Node short name; feeds the resource name. Capped at 10 so kv-hd-<service>-<env> stays within the 24-char Key Vault name limit.')
@maxLength(10)
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

@description('Resource ID of the shared Log Analytics workspace (provisioned by platform/, packet 14) to which Key Vault diagnostics are routed (invariant 22). This module does NOT create the workspace.')
param logAnalyticsWorkspaceId string

@description('Soft-delete retention window in days (7-90).')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

// Vault names are <=24 chars. Fixed parts: 'kv-hd-' (6) + the longest env
// suffix '-staging' (8) = 14, so `service` is capped at @maxLength(10) above —
// kv-hd-<10>-staging = 24 exactly, so the composed name can never overflow.
var name = 'kv-hd-${service}-${env}'

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    accessPolicies: []
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-to-law'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The Key Vault data-plane URI (https://<name>.vault.azure.net/).')
output vaultUri string = keyVault.properties.vaultUri

@description('The Key Vault resource ID — pass to consumers that scope RBAC or reference secrets by URI.')
output vaultId string = keyVault.id

@description('The Key Vault resource name.')
output name string = keyVault.name
