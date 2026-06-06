// =============================================================================
// modules/data/containerRegistry.bicep  (ADR-0077 packet 14)
// Microsoft.ContainerRegistry/registries — the SHARED per-env container-IMAGE
// registry (acrhdshared{env}, invariant 35). This is the image ACR consumers
// pull from via managed identity + AcrPull RBAC; it is NOT a Bicep-module
// registry (the cross-repo module registry was DROPPED by the ADR-0077
// amendment — modules resolve by local path). The naming resemblance to the
// dropped `acrhdbicep` is coincidental.
//
// NAMING: ACR names are 5-50 chars, alphanumeric ONLY (no hyphens). So the
// usual `<type>-hd-<x>-<env>` scheme does not apply — we compose a hyphen-free
// `acrhdshared{env}` (e.g. acrhdshareddev).
//
// adminUserEnabled is false: consumers authenticate with managed identity, not
// the admin username/password pair (no admin credential ever leaves Azure — D7).
// =============================================================================

@description('Target environment.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param env string

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required Grid tags: hd:node, hd:env, hd:owner, hd:cost-center, hd:dr-tier, hd:adr. The consumer composes these once and passes them in.')
param tags object

@description('ACR sku. Standard is the Grid default for the shared image registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

// ACR names: 5-50 chars, alphanumeric only (no hyphens). Hence the hyphen-free
// composition rather than the standard <type>-hd-<service>-<env> scheme.
var name = 'acrhdshared${env}'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    // Consumers pull via managed identity + AcrPull RBAC — never the admin
    // username/password pair. Keeping this false means no admin credential
    // exists to leak (D7 / invariant 91).
    adminUserEnabled: false
  }
}

@description('The container registry resource ID — the canonical reference for AcrPull RBAC scoping and per-Node image references.')
output id string = registry.id

@description('The container registry resource name.')
output name string = registry.name

@description('The registry login server (e.g. acrhdshareddev.azurecr.io) — the image-pull host.')
output loginServer string = registry.properties.loginServer
