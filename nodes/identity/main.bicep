targetScope = 'resourceGroup'

@description('This leaf is deliberately dev-only until recovery and lifecycle acceptance are complete.')
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

@description('First app creation only: public placeholder at a named revision, without secrets or registry credentials.')
param bootstrap bool = false

@sealed()
type appConfiguration = {
  @minLength(1)
  image: string
  @minLength(1)
  trafficRevision: string
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

@description('Explicit reviewed initialization/maintenance only. Null references the CD-owned app; never overwrites image, revisions or traffic in steady state.')
param appUpdate appConfiguration?

@description('Create lifecycle queues only after separate consumer/recovery review. This does not enable API delivery or assign roles.')
param provisionLifecycleQueues bool = false

var platformGroup = 'rg-hd-platform-${env}'
var appName = 'ca-hd-identity-${env}'
var manageApp = bootstrap || appUpdate != null

resource environment 'Microsoft.App/managedEnvironments@2025-07-01' existing = {
  name: 'cae-hd-${env}'
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
resource existingApp 'Microsoft.App/containerApps@2025-07-01' existing = if (!manageApp) {
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

module app '../../modules/compute/containerApp.bicep' = if (manageApp) {
  name: 'identity-app'
  params: {
    service: 'identity'
    env: env
    location: location
    tags: tags
    containerAppEnvironmentId: environment.id
    image: bootstrap ? 'mcr.microsoft.com/azuredocs/aci-helloworld@sha256:456a1150aa41340a14c7be1342deda2cde9e6e7df9fde6b8a69de0ae04f92fad' : appUpdate!.image
    revisionSuffix: bootstrap ? 'bootstrap' : ''
    targetPort: bootstrap ? 80 : 8080
    traffic: [{ revisionName: bootstrap ? '${appName}--bootstrap' : appUpdate!.trafficRevision, latestRevision: false, weight: 100 }]
    minReplicas: bootstrap ? 0 : 1
    maxReplicas: 2
    cpu: '0.25'
    memory: '0.5Gi'
    envVars: bootstrap ? [] : runtimeEnv
    registries: bootstrap ? [] : [{ server: registry.properties.loginServer, identity: 'system' }]
    probes: bootstrap ? [] : runtimeProbes
  }
}

// Container Apps permits at most 10 failures; retain a 150-second startup allowance.
var runtimeProbes = [
  { type: 'Startup', httpGet: { path: '/health/live', port: 8080 }, periodSeconds: 15, failureThreshold: 10 }
  { type: 'Liveness', httpGet: { path: '/health/live', port: 8080 }, periodSeconds: 10, failureThreshold: 3 }
  { type: 'Readiness', httpGet: { path: '/health', port: 8080 }, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 3 }
]

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

@description('Identity API hostname on the existing shared environment.')
output fqdn string = manageApp ? app!.outputs.fqdn : existingApp!.properties.configuration.ingress.fqdn
