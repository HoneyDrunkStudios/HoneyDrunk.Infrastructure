// =============================================================================
// modules/messaging/serviceBusNamespace.bicep  (ADR-0077 packet 13)
// Microsoft.ServiceBus/namespaces — Service Bus namespace. Standard sku.
// No raw secret params (D7 / invariant 91); SAS keys are never templated —
// consumers use managed-identity RBAC or pull connection strings from Key Vault.
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

@description('Service Bus sku. Standard is the Grid default (topics + queues).')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

var name = 'sb-hd-${service}-${env}'

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
}

@description('The Service Bus namespace resource ID.')
output id string = serviceBus.id

@description('The Service Bus namespace resource name.')
output name string = serviceBus.name

@description('The Service Bus namespace endpoint (https://<name>.servicebus.windows.net:443/).')
output endpoint string = serviceBus.properties.serviceBusEndpoint
