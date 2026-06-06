// =============================================================================
// modules/compute/containerAppEnvironment.bicep  (ADR-0077 packet 14)
// Microsoft.App/managedEnvironments — the SHARED per-env Container Apps
// Environment (cae-hd-{env}, invariant 35). One per environment, owned by the
// platform layer (NOT per-service): the `env`-only naming reflects that (there
// is no `service` param). Per-Node container apps join this environment by ID.
//
// LOGGING — D7 trap avoidance: app logs route via `azure-monitor` (NOT
// `log-analytics`), so we DO NOT pass the Log Analytics customerId/sharedKey
// pair into appLogsConfiguration (sharedKey is a secret — D7 / invariant 91,
// and would trip the secret-hygiene lint). Instead a child
// Microsoft.Insights/diagnosticSettings resource scoped to this environment
// routes ContainerAppConsoleLogs + ContainerAppSystemLogs + AllMetrics to the
// shared workspace BY RESOURCE ID — no key material in the template.
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

@description('Resource ID of the shared Log Analytics workspace (from logAnalyticsWorkspace.bicep) that app/system logs are routed to via diagnostic settings — BY ID, no shared key (D7).')
param logAnalyticsWorkspaceId string

var name = 'cae-hd-${env}'

resource managedEnvironment 'Microsoft.App/managedEnvironments@2025-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    // azure-monitor destination keeps the Log Analytics sharedKey OUT of the
    // template (D7). Destination details are supplied by the child diagnostic
    // settings below, which reference the workspace by ID only.
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-to-law'
  scope: managedEnvironment
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
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

@description('The Container Apps Environment resource ID — the canonical reference per-Node container apps join.')
output id string = managedEnvironment.id

@description('The Container Apps Environment resource name.')
output name string = managedEnvironment.name

@description('The environment default domain (the ingress suffix for apps in this environment).')
output defaultDomain string = managedEnvironment.properties.defaultDomain
