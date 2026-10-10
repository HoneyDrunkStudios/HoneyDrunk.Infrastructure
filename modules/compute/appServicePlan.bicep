@description('Dedicated Linux App Service plan name.')
param name string
param location string = resourceGroup().location
param tags object
@description('Reviewed environment sizing. B1 is the selected dev size; other environments need separate parameters and approval.')
param skuName string = 'B1'
param skuTier string = 'Basic'
@minValue(1)
param capacity int = 1

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: name
  location: location
  tags: tags
  kind: 'linux'
  sku: { name: skuName, tier: skuTier, capacity: capacity }
  properties: { reserved: true }
}
output id string = plan.id
