@description('Existing logical server in this module deployment resource group. This module cannot change server/admin/network configuration.')
@minLength(1)
param serverName string

@description('Short service name used only for the separately owned database.')
@maxLength(13)
param service string

@description('Environment name.')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Azure region.')
param location string = resourceGroup().location

@description('Grid ownership and cost tags.')
param tags object

resource server 'Microsoft.Sql/servers@2025-01-01' existing = {
  name: serverName
}

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
