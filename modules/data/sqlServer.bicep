@description('Logical server name. Server/network/admin ownership is separate from application databases.')
@minLength(1)
@maxLength(63)
param serverName string

param location string = resourceGroup().location
param tags object

@description('Approved workforce Entra administrator group display name. No SQL password is created.')
@minLength(1)
param administratorLogin string

@description('Approved workforce Entra administrator group object ID.')
@minLength(36)
@maxLength(36)
param administratorObjectId string

@sealed()
type firewallRule = {
  name: string
  startIpAddress: string
  endIpAddress: string
}

@description('Reviewed explicit addresses; empty denies public clients. Never use the Azure-services bypass. Incremental deployment does not remove old rules.')
param firewallRules firewallRule[] = []

resource server 'Microsoft.Sql/servers@2025-01-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: administratorLogin
      sid: administratorObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

resource firewall 'Microsoft.Sql/servers/firewallRules@2025-01-01' = [for rule in firewallRules: {
  parent: server
  name: rule.name
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

output serverFqdn string = server.properties.fullyQualifiedDomainName
