// =============================================================================
// modules/secrets/appConfigurationStore.bicep  (ADR-0077 packet 13)
// Microsoft.AppConfiguration/configurationStores — the SINGLE shared App
// Configuration store per environment (ADR-0005): appcs-hd-shared-{env},
// label-partitioned per Node, read-only at runtime via Managed Identity. This
// is a shared-foundation resource (provisioned from platform/), NOT per-Node.
// Local auth (access keys / connection strings) is disabled — MI/RBAC only
// (ADR-0005 / D7 / invariant 91); secret-shaped values live in Key Vault and
// are surfaced via App Configuration Key Vault references.
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

@description('App Configuration sku (free / developer / standard / premium).')
@allowed([
  'free'
  'developer'
  'standard'
  'premium'
])
param sku string = 'standard'

// ADR-0005: ONE shared store per environment, label-partitioned per Node.
var name = 'appcs-hd-shared-${env}'

resource configStore 'Microsoft.AppConfiguration/configurationStores@2024-06-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    // MI/RBAC only — access-key / connection-string auth disabled (ADR-0005).
    disableLocalAuth: true
  }
}

@description('The App Configuration data-plane endpoint (https://<name>.azconfig.io). Reaches Nodes as AZURE_APPCONFIG_ENDPOINT (invariant 18).')
output endpoint string = configStore.properties.endpoint

@description('The App Configuration store resource ID.')
output id string = configStore.id

@description('The App Configuration store resource name.')
output name string = configStore.name
