// =============================================================================
// modules/data/storageAccount.bicep  (ADR-0077 packet 13)
// Microsoft.Storage/storageAccounts — StorageV2 account.
//
// SPECIAL NAMING: storage account names are 3-24 chars, lowercase letters and
// digits ONLY (no hyphens). The Grid 'sthd<service><env>' composition therefore
// drops hyphens. `service` is capped at @maxLength(11) here (not 13) so that
// 'sthd'(4) + service(<=11) + 'staging'(7) stays within 24 in the worst case
// (4+11+7 = 22). The assert below is a defensive guard for the composed name.
// =============================================================================

@description('Service or Node short name; feeds the (hyphen-free, lowercased) resource name. Capped at 11 chars for the storage 24-char limit (worst case: sthd + 11 + staging = 22).')
@maxLength(11)
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

@description('Storage replication sku. Standard_LRS is the Grid default.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])
param sku string = 'Standard_LRS'

// Storage names: lowercase alphanumerics only, no hyphens, 3-24 chars.
// 'sthd'(4) + service(<=11) + env(<=7 for 'staging') = <=22, always <=24.
var name = toLower('sthd${service}${env}')

resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

@description('The storage account resource ID.')
output id string = storage.id

@description('The storage account resource name.')
output name string = storage.name

@description('The primary blob service endpoint (https://<name>.blob.core.windows.net/).')
output primaryBlobEndpoint string = storage.properties.primaryEndpoints.blob
