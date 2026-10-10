@description('Existing platform-owned SQL server. This module writes only the explicit subnet rule.')
param serverName string
param ruleName string
param subnetId string
resource server 'Microsoft.Sql/servers@2025-01-01' existing = { name: serverName }
resource rule 'Microsoft.Sql/servers/virtualNetworkRules@2025-01-01' = {
  parent: server
  name: ruleName
  properties: {
    virtualNetworkSubnetId: subnetId
    ignoreMissingVnetServiceEndpoint: false
  }
}
