// =============================================================================
// modules/secrets/appConfigurationStore.bicep  (ADR-0077 packet 13)
// Microsoft.AppConfiguration/configurationStores — App Configuration store.
// standard sku. No raw secret params (D7 / invariant 91); secret-shaped values
// belong in Key Vault and are referenced from App Configuration by URI.
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

@description('App Configuration sku. Standard is the Grid default.')
@allowed([
  'free'
  'standard'
])
param sku string = 'standard'

var name = 'appcs-hd-${service}-${env}'

resource configStore 'Microsoft.AppConfiguration/configurationStores@2024-06-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    disableLocalAuth: false
  }
}

@description('The App Configuration data-plane endpoint (https://<name>.azconfig.io).')
output endpoint string = configStore.properties.endpoint

@description('The App Configuration store resource ID.')
output id string = configStore.id

@description('The App Configuration store resource name.')
output name string = configStore.name
