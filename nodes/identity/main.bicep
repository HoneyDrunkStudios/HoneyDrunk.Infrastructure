targetScope = 'resourceGroup'

@description('Environment-qualified source; only dev parameters are implemented and dispatch-approved.')
@allowed(['dev'])
param env string

@description('Azure region.')
param location string = resourceGroup().location

@description('Grid ownership and cost tags.')
param tags object

@description('Create only the Identity Basic database on the existing platform-owned shared server. No server/admin/firewall writes.')
param provisionDatabase bool = false

@description('Create the dedicated vault only with an approved resource/cost plan. No certificate or secret value is created.')
param provisionVault bool = false

@description('First creation only: dedicated Linux plan and stopped placeholder Web App with system MI. No grants, credentials or serving API.')
param bootstrap bool = false

@sealed()
type appConfiguration = {
  @minLength(1)
  image: string
  @minLength(1)
  authority: string
  @minLength(1)
  issuer: string
  @minLength(1)
  audience: string
  @minLength(1)
  mobileClientId: string
  @minLength(1)
  apiScope: string
  @minLength(36)
  graphTenantId: string
  @minLength(36)
  graphClientId: string
  @minLength(1)
  graphCertificateSecretName: string
  allowedOrigins: string[]
  @minLength(1)
  otlpEndpoint: string
}

@description('Explicit reviewed initialization/maintenance only. Null references the CD-owned app; never overwrites its image or settings in steady state.')
param appUpdate appConfiguration?

@description('Create lifecycle queues only after separate consumer/recovery review. This does not enable API delivery or assign roles.')
param provisionLifecycleQueues bool = false

var platformGroup = 'rg-hd-platform-${env}'
@description('Proposed globally unique Web App name. Verify availability before provisioning; override for a reviewed collision resolution.')
param appName string = 'app-hd-identity-${env}'
@description('Dedicated Linux plan sizing for the selected environment.')
param planSkuName string = 'B1'
param planSkuTier string = 'Basic'
@minValue(1)
param planCapacity int = 1
var planName = 'asp-hd-identity-${env}'
var manageApp = bootstrap || appUpdate != null

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' existing = if (manageApp) {
  name: 'vnet-hd-apps-${env}/snet-app-service'
  scope: resourceGroup(platformGroup)
}
resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: 'acrhdshared${env}'
  scope: resourceGroup(platformGroup)
}
resource logs 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: 'log-hd-shared-${env}'
  scope: resourceGroup(platformGroup)
}
resource existingApp 'Microsoft.Web/sites@2024-11-01' existing = if (!manageApp) {
  name: appName
}
resource vault 'Microsoft.KeyVault/vaults@2024-11-01' existing = if (!bootstrap && appUpdate != null) {
  name: 'kv-hd-identity-${env}'
}
resource server 'Microsoft.Sql/servers@2025-01-01' existing = if (!bootstrap && appUpdate != null) {
  name: 'sql-hd-shared-${env}'
  scope: resourceGroup(platformGroup)
}

module database '../../modules/data/sqlDatabase.bicep' = if (provisionDatabase) {
  name: 'identity-sql'
  scope: resourceGroup(platformGroup)
  params: {
    serverName: 'sql-hd-shared-${env}'
    service: 'identity'
    env: env
    location: location
    tags: tags
  }
}
module newVault '../../modules/secrets/keyVault.bicep' = if (provisionVault) {
  name: 'identity-vault'
  params: {
    service: 'identity'
    env: env
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logs.id
  }
}

// Graph certificate remains in the external tenant's app; the private certificate
// is resolved from this node's Key Vault only after an approved setup/rotation.
var originEnv = [for (origin, i) in (appUpdate.?allowedOrigins ?? []): {
  name: 'Cors__AllowedOrigins__${i}'
  value: origin
}]

var runtimeEnv = appUpdate == null ? [] : concat([
  { name: 'ASPNETCORE_ENVIRONMENT', value: 'Production' }
  { name: 'ASPNETCORE_HTTP_PORTS', value: '8080' }
  { name: 'HONEYDRUNK_NODE_ID', value: 'honeydrunk-identity' }
  { name: 'AZURE_KEYVAULT_URI', value: vault!.properties.vaultUri }
  { name: 'ConnectionStrings__identity', value: 'Server=tcp:${server!.properties.fullyQualifiedDomainName},1433;Database=sqldb-hd-identity-${env};Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=15' }
  { name: 'Entra__Authority', value: appUpdate!.authority }
  { name: 'Entra__Issuer', value: appUpdate!.issuer }
  { name: 'Entra__Audience', value: appUpdate!.audience }
  { name: 'Entra__MobileClientId', value: appUpdate!.mobileClientId }
  { name: 'Entra__ApiScope', value: appUpdate!.apiScope }
  { name: 'Entra__Graph__CredentialMode', value: 'Certificate' }
  { name: 'Entra__Graph__TenantId', value: appUpdate!.graphTenantId }
  { name: 'Entra__Graph__ClientId', value: appUpdate!.graphClientId }
  { name: 'Entra__Graph__CertificateSecretName', value: appUpdate!.graphCertificateSecretName }
  { name: 'OTEL_EXPORTER_OTLP_ENDPOINT', value: appUpdate!.otlpEndpoint }
], originEnv)

// Only bootstrap creates the dedicated plan. Later sizing changes require a
// reviewed plan-only operation; default node runs do not mutate compute.
module plan '../../modules/compute/appServicePlan.bicep' = if (bootstrap) {
  name: 'identity-app-service-plan'
  params: {
    name: planName
    location: location
    tags: tags
    skuName: planSkuName
    skuTier: planSkuTier
    capacity: planCapacity
  }
}
module app '../../modules/compute/appServiceContainer.bicep' = if (manageApp) {
  name: 'identity-app-service'
  params: {
    name: appName
    location: location
    tags: tags
    planId: bootstrap ? plan!.outputs.id : resourceId('Microsoft.Web/serverfarms', planName)
    subnetId: subnet!.id
    image: bootstrap ? 'mcr.microsoft.com/azuredocs/aci-helloworld@sha256:456a1150aa41340a14c7be1342deda2cde9e6e7df9fde6b8a69de0ae04f92fad' : appUpdate!.image
    enabled: !bootstrap
    port: bootstrap ? 80 : 8080
    healthPath: bootstrap ? '/' : '/health'
    appSettings: bootstrap ? [] : concat(runtimeEnv, [{ name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${registry.properties.loginServer}' }])
  }
}

// Source-only queue preparation; no topics are needed by the current per-consumer
// queue contract. Consumer implementation, grants and lifecycle activation are separate.
module queues '../../modules/messaging/serviceBusQueue.bicep' = [for name in ['identity-lifecycle-acks', 'pocketquests-lifecycle']: if (provisionLifecycleQueues) {
  name: 'identity-${name}'
  scope: resourceGroup(platformGroup)
  params: {
    namespaceName: 'sb-hd-shared-${env}'
    queueName: name
  }
}]

@description('App managed identity. SQL contained-user and Azure resource grants require separate approved setup.')
output principalId string = manageApp ? app!.outputs.principalId : existingApp!.identity.principalId

@description('Azure-returned Web App hostname; never infer a live hostname from the planned name.')
output fqdn string = manageApp ? app!.outputs.fqdn : existingApp!.properties.defaultHostName

