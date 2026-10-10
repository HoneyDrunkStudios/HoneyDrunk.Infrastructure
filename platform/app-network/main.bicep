targetScope = 'resourceGroup'
@allowed(['dev'])
param env string
param location string = resourceGroup().location
param tags object

@sealed()
type networkConfiguration = {
  addressPrefix: string
  subnetPrefix: string
}
@description('Null makes no network writes. Exact CIDRs must be approved against Azure, operator and planned peering networks before apply.')
param networkSetup networkConfiguration?

module network '../../modules/networking/appServiceNetwork.bicep' = if (networkSetup != null) {
  name: 'app-service-network'
  params: {
    name: 'vnet-hd-apps-${env}'
    location: location
    tags: tags
    addressPrefix: networkSetup!.addressPrefix
    subnetPrefix: networkSetup!.subnetPrefix
  }
}
@description('Planned resource reference only, not existence or address availability evidence.')
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-hd-apps-${env}', 'snet-app-service')

