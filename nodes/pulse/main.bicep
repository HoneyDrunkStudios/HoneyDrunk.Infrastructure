// =============================================================================
// nodes/pulse/main.bicep  (ADR-0077 — first Node leaf template)
// The HoneyDrunk.Pulse Node: the observability collector Container App
// (ca-hd-pulse-<env>) deployed into rg-hd-pulse-<env>, joined to the SHARED
// Container Apps Environment in rg-hd-platform-<env> (cae-hd-<env>).
//
// This leaf CONSUMES shared-foundation resources by `existing` reference
// (convention-named, no hand-pasted ARM IDs) and CREATES only what the Node
// owns: its Container App + the RBAC its system-assigned identity needs to
// pull its image, read App Configuration, and resolve Key Vault secret refs.
//
//   shared (rg-hd-platform-<env>, existing):  cae-hd-<env>, acrhdshared<env>,
//                                             appcs-hd-shared-<env>
//   node   (rg-hd-pulse-<env>):    kv-hd-pulse-<env> (existing) + the app (new)
//
// The Key Vault, its secret VALUES, and App Configuration key-values are NOT
// managed here (D7 / the IaC boundary): the vault is referenced, its secrets
// surfaced to the app as Key Vault references by URI. Adopting kv-hd-pulse-<env>
// itself into IaC (the keyVault module) is a tracked follow-up.
//
// Modules resolve by LOCAL relative path (two `../` — nodes/pulse is two levels
// below the repo root; modules/ is a sibling of nodes/). No registry, no `br:`.
// =============================================================================

targetScope = 'resourceGroup'

@description('Target environment. Selects the per-env resource names and the rg-hd-platform-<env> shared RG.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param env string

@description('Azure region. Defaults to the resource group location (rg-hd-pulse-<env>).')
param location string = resourceGroup().location

@description('Required Grid tags: hd:node, hd:env, hd:owner, hd:cost-center, hd:dr-tier, hd:adr. Composed by the param file.')
param tags object

@description('The pulse-collector container image (acrhdshared<env>.azurecr.io/honeydrunk-pulse-collector:<tag>). Owned by the param file until Pulse CD owns image promotion.')
param image string

@description('Bootstrap pass. A brand-new system-MI app cannot deploy in one shot: the first revision needs AcrPull (private image) + Key Vault Secrets User (secret refs), but those grants need the MI, which needs the app, which blocks on the revision — deadlock. Set true for the FIRST deploy of a new Node: it runs a PUBLIC placeholder image with no registry/secret wiring (revision goes healthy with zero RBAC) while STILL creating the role assignments. Then deploy again with bootstrap=false (default) — RBAC now exists, so the real private image pulls and the secret refs resolve. See README.')
param bootstrap bool = false

// Public placeholder for the bootstrap pass — listens on :80, needs no registry
// auth or secrets, so the first revision of a fresh system-MI app is healthy with
// zero RBAC (which is what lets the role-assignment grants then run).
var bootstrapImage = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
var bootstrapTargetPort = 80
var realTargetPort = 8080

// --- Built-in role definition GUIDs -----------------------------------------
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
var appConfigDataReaderRoleId = '516239f1-63e1-4d78-a4de-a74fb236a071' // App Configuration Data Reader
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User

// --- ASP.NET Core environment name (HONEYDRUNK_NODE_ID stays the Node id) -----
var aspnetCoreEnvironment = env == 'dev' ? 'Development' : (env == 'staging' ? 'Staging' : 'Production')

var platformResourceGroup = 'rg-hd-platform-${env}'

// --- Shared-foundation resources (existing — provisioned by platform/) --------
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-07-01' existing = {
  name: 'cae-hd-${env}'
  scope: resourceGroup(platformResourceGroup)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: 'acrhdshared${env}'
  scope: resourceGroup(platformResourceGroup)
}

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2024-06-01' existing = {
  name: 'appcs-hd-shared-${env}'
  scope: resourceGroup(platformResourceGroup)
}

// --- Node-owned Key Vault (existing — referenced, not managed here) -----------
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: 'kv-hd-pulse-${env}'
}

// --- Container App secrets: Key Vault references via the system identity -------
var secrets = [
  {
    name: 'posthog-apikey'
    identity: 'system'
    keyVaultUrl: '${keyVault.properties.vaultUri}secrets/PostHog--ApiKey'
  }
  {
    name: 'sentry-dsn'
    identity: 'system'
    keyVaultUrl: '${keyVault.properties.vaultUri}secrets/Sentry--Dsn'
  }
]

// --- Container environment ----------------------------------------------------
// The 4 Grid bootstrap env vars (invariant 18) — safe in BOTH passes. The
// bootstrap pass uses ONLY these.
var baseEnvVars = [
  {
    name: 'AZURE_KEYVAULT_URI'
    value: keyVault.properties.vaultUri
  }
  {
    name: 'AZURE_APPCONFIG_ENDPOINT'
    value: appConfiguration.properties.endpoint
  }
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: aspnetCoreEnvironment
  }
  {
    name: 'HONEYDRUNK_NODE_ID'
    value: 'honeydrunk-pulse'
  }
]
// Real-pass-only env: the app's own port binding (the bootstrap placeholder
// listens on :80, not :8080) and the secretRef vars — both only valid once the
// real image + `secrets` are wired (bootstrap=false).
var realEnvVars = [
  {
    name: 'ASPNETCORE_URLS'
    value: 'http://+:8080'
  }
  {
    name: 'PostHog__ApiKey'
    secretRef: 'posthog-apikey'
  }
  {
    name: 'Sentry__Dsn'
    secretRef: 'sentry-dsn'
  }
]

// --- Private registry (image pull authenticated by the system identity) -------
var registries = [
  {
    server: containerRegistry.properties.loginServer
    identity: 'system'
  }
]

// --- Effective values: the bootstrap pass strips the private-image / secret /
// registry wiring so the first revision is healthy without any RBAC; the real
// pass (bootstrap=false) wires the actual image, secrets, and registry.
var effectiveImage = bootstrap ? bootstrapImage : image
var effectiveTargetPort = bootstrap ? bootstrapTargetPort : realTargetPort
var effectiveEnvVars = bootstrap ? baseEnvVars : concat(baseEnvVars, realEnvVars)
var effectiveSecrets = bootstrap ? [] : secrets
var effectiveRegistries = bootstrap ? [] : registries

// --- The Pulse Container App --------------------------------------------------
module app '../../modules/compute/containerApp.bicep' = {
  name: 'pulse-app'
  params: {
    service: 'pulse'
    containerName: 'pulse'
    env: env
    location: location
    tags: tags
    containerAppEnvironmentId: containerAppEnvironment.id
    image: effectiveImage
    targetPort: effectiveTargetPort
    externalIngress: true
    transport: 'auto'
    allowInsecure: false
    minReplicas: 0
    maxReplicas: 10
    cpu: '0.25'
    memory: '0.5Gi'
    envVars: effectiveEnvVars
    secrets: effectiveSecrets
    registries: effectiveRegistries
    scaleRules: [] // Pulse is request-driven on ingress; no KEDA trigger.
  }
}

// --- RBAC for the app's system-assigned identity ------------------------------
// Each grant goes through the generic roleAssignment module, which folds the
// app's principalId into the assignment name — so a delete-and-recreate (new MI)
// produces a NEW assignment rather than an illegal update of the immutable
// principalId on the existing one. The two shared-resource grants are deployed
// into the platform RG (cross-RG); the Key Vault grant lands in this Node's RG.
// Grants sit at RG scope (a module cannot scope to a single resource — BCP134),
// which is effectively resource-scoped here: the roles are resource-TYPE scoped
// and each RG is single-purpose. See the module header.

// Key Vault Secrets User — the Node's own vault (this RG); resolves the refs.
module keyVaultSecretsUser '../../modules/identity/roleAssignment.bicep' = {
  name: 'pulse-kv-secrets-user'
  params: {
    principalId: app.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

// AcrPull — the shared ACR (cross-RG, rg-hd-platform-<env>).
module acrPull '../../modules/identity/roleAssignment.bicep' = {
  name: 'pulse-acrpull'
  scope: resourceGroup(platformResourceGroup)
  params: {
    principalId: app.outputs.principalId
    roleDefinitionId: acrPullRoleId
  }
}

// App Configuration Data Reader — the shared store (cross-RG, rg-hd-platform).
module appConfigReader '../../modules/identity/roleAssignment.bicep' = {
  name: 'pulse-appcs-reader'
  scope: resourceGroup(platformResourceGroup)
  params: {
    principalId: app.outputs.principalId
    roleDefinitionId: appConfigDataReaderRoleId
  }
}

@description('Principal ID of the Pulse Container App system-assigned managed identity.')
output principalId string = app.outputs.principalId

@description('Fully-qualified ingress domain of the Pulse Container App on the shared environment.')
output fqdn string = app.outputs.fqdn

@description('The Pulse Container App resource name.')
output name string = app.outputs.name
