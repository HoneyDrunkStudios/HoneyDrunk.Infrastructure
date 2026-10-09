@description('Short service name used for the dedicated logical server and database.')
@maxLength(13)
param service string

@description('Environment name.')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Azure region.')
param location string = resourceGroup().location

@description('Grid ownership and cost tags.')
param tags object

@description('Approved workforce-tenant Entra administrator group display name. No SQL password is created.')
@minLength(1)
param administratorLogin string

@description('Approved workforce-tenant Entra administrator group object ID.')
@minLength(36)
@maxLength(36)
param administratorObjectId string

@sealed()
type firewallRule = {
  name: string
  startIpAddress: string
  endIpAddress: string
}

@description('Explicit reviewed egress ranges. Empty denies all public clients. Never use the 0.0.0.0 Azure-services bypass.')
param firewallRules firewallRule[] = []

resource server 'Microsoft.Sql/servers@2025-01-01' = {
  name: 'sql-hd-${service}-${env}'
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

// Predictable low-volume dev cost: 5 DTUs, 2 GiB. No serverless auto-pause or
// free-offer assumption. A different performance tier is a reviewed module change.
resource database 'Microsoft.Sql/servers/databases@2025-01-01' = {
  parent: server
  name: 'sqldb-hd-${service}-${env}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}

resource retention 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2025-01-01' = {
  parent: database
  name: 'default'
  properties: {
    retentionDays: 7
  }
}

@description('SQL endpoint for passwordless clients.')
output serverFqdn string = server.properties.fullyQualifiedDomainName

@description('Database name. Schema is deployed separately with the reviewed DACPAC workflow.')
output databaseName string = database.name
