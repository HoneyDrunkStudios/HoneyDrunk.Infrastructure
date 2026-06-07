// =============================================================================
// platform/main.bicep  (ADR-0077 packet 14)
// The SHARED-FOUNDATION layer — deploys into rg-hd-platform-{env}. Composes the
// per-env shared resources owned by no single Node (invariant 35):
//   - Log Analytics workspace  (log-hd-shared-{env})  — declared first; others
//                                                        reference its id.
//   - Container Apps Environment (cae-hd-{env})        — joins the workspace.
//   - container-image ACR        (acrhdshared{env})    — the only ACR.
//   - shared Service Bus         (sb-hd-shared-{env})  — service='shared'.
//   - shared App Configuration   (appcs-hd-shared-{env}) — one per env, MI-only
//                                                          (ADR-0005).
//
// Every shared resource's id is EXPORTED as an output: per-Node leaf templates
// under nodes/{node}/ reference these outputs instead of hand-pasting ARM
// resource-ID strings (the gap this layer closes). See platform/README.md.
//
// Modules resolve by LOCAL relative path (one `../` — modules/ is a sibling of
// platform/). No registry, no `br:` references. No secret values (D7).
// =============================================================================

targetScope = 'resourceGroup'

@description('Target environment. Selects the per-env shared-resource names (cae-hd-{env}, acrhdshared{env}, etc.) and the rg-hd-platform-{env} target.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param env string

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required Grid tags: hd:node, hd:env, hd:owner, hd:cost-center, hd:dr-tier, hd:adr. Composed once by the param file and applied to every shared resource.')
param tags object

@description('Container registry SKU. dev uses Basic to match the existing acrhdshareddev; staging/prod use Standard.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param containerRegistrySku string = 'Standard'

@description('App Configuration SKU. dev uses developer to match the existing appcs-hd-shared-dev; staging/prod use standard.')
@allowed([
  'free'
  'developer'
  'standard'
  'premium'
])
param appConfigurationSku string = 'standard'

// --- Log Analytics (first — the CAE + per-Node diagnostics reference its id) --
module logAnalyticsWorkspace '../modules/observability/logAnalyticsWorkspace.bicep' = {
  name: 'platform-law'
  params: {
    env: env
    location: location
    tags: tags
  }
}

// --- Container Apps Environment (routes app/system logs to the workspace) -----
module containerAppEnvironment '../modules/compute/containerAppEnvironment.bicep' = {
  name: 'platform-cae'
  params: {
    env: env
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

// --- container-image ACR (acrhdshared{env}) -----------------------------------
module containerRegistry '../modules/data/containerRegistry.bicep' = {
  name: 'platform-acr'
  params: {
    env: env
    location: location
    tags: tags
    sku: containerRegistrySku
  }
}

// --- shared Service Bus (sb-hd-shared-{env}) — reuses the packet-13 module ----
module serviceBusNamespace '../modules/messaging/serviceBusNamespace.bicep' = {
  name: 'platform-sb'
  params: {
    service: 'shared'
    env: env
    location: location
    tags: tags
  }
}

// --- shared App Configuration (appcs-hd-shared-{env}) — ADR-0005, MI-only -----
module appConfigurationStore '../modules/secrets/appConfigurationStore.bicep' = {
  name: 'platform-appcs'
  params: {
    env: env
    location: location
    tags: tags
    sku: appConfigurationSku
  }
}

@description('Shared Log Analytics workspace resource ID — the canonical reference for per-Node diagnostics and App Insights.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.id

@description('Shared Container Apps Environment resource ID — the canonical reference per-Node container apps join.')
output containerAppEnvironmentId string = containerAppEnvironment.outputs.id

@description('Shared container-image ACR resource ID — the canonical reference for AcrPull RBAC scoping.')
output containerRegistryId string = containerRegistry.outputs.id

@description('Shared container-image ACR login server (e.g. acrhdshareddev.azurecr.io) — the image-pull host per-Node templates reference.')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('Shared Service Bus namespace resource ID — the canonical reference for per-Node queue/topic + RBAC wiring.')
output serviceBusNamespaceId string = serviceBusNamespace.outputs.id

@description('Shared App Configuration store resource ID (ADR-0005) — the canonical reference for per-Node Managed-Identity read access.')
output appConfigurationStoreId string = appConfigurationStore.outputs.id

@description('Shared App Configuration endpoint — reaches Nodes as AZURE_APPCONFIG_ENDPOINT (invariant 18).')
output appConfigurationEndpoint string = appConfigurationStore.outputs.endpoint
