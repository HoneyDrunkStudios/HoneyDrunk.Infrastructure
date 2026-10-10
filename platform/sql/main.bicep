targetScope = 'resourceGroup'

@allowed(['dev'])
param env string

@allowed(['eastus2'])
param location string = 'eastus2'

param tags object

@sealed()
type sqlSetup = {
  @minLength(1)
  administratorLogin: string
  @minLength(36)
  @maxLength(36)
  administratorObjectId: string
  firewallRules: {
    name: string
    startIpAddress: string
    endIpAddress: string
  }[]
}

@description('Explicit approved server/admin/firewall setup or maintenance. Null makes no SQL writes. Never accepts database or app configuration.')
param serverSetup sqlSetup?

module server '../../modules/data/sqlServer.bicep' = if (serverSetup != null) {
  name: 'shared-sql-server'
  params: {
    serverName: 'sql-hd-shared-${env}'
    location: location
    tags: tags
    administratorLogin: serverSetup!.administratorLogin
    administratorObjectId: serverSetup!.administratorObjectId
    firewallRules: serverSetup!.firewallRules
  }
}

@description('Planned name only; an omitted serverSetup does not prove this server exists.')
output serverName string = 'sql-hd-shared-${env}'
