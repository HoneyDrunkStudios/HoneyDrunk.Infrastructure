@description('Dedicated network for App Service integration. CIDRs require an approved overlap review; none are defaulted.')
param name string
param location string = resourceGroup().location
param tags object
param addressPrefix string
param subnetPrefix string
param subnetName string = 'snet-app-service'

resource network 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [addressPrefix] }
    subnets: [{
      name: subnetName
      properties: {
        addressPrefix: subnetPrefix
        delegations: [{ name: 'app-service', properties: { serviceName: 'Microsoft.Web/serverFarms' } }]
        serviceEndpoints: [{ service: 'Microsoft.Sql', locations: [location] }]
      }
    }]
  }
}
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', network.name, subnetName)
