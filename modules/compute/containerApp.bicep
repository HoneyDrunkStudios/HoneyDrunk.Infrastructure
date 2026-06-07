// =============================================================================
// modules/compute/containerApp.bicep  (ADR-0077 packet 13)
// Microsoft.App/containerApps — one Container App per Node (invariant 34).
// System-assigned managed identity (invariant 34), Multiple revision mode
// (invariant 36). Consumes the shared Container Apps Environment by ID; does
// NOT create it. No raw secret params (D7 / invariant 91) — secret material is
// referenced from Key Vault by URI via the `secrets` array (identity: 'system'),
// never passed as a literal value.
// =============================================================================

@description('Service or Node short name; feeds the resource name.')
@maxLength(13)
param service string

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

@description('Resource ID of the shared Container Apps Environment (cae-hd-<env>) provisioned by platform/ (packet 14). This module does NOT create the environment.')
param containerAppEnvironmentId string

@description('Container image reference (e.g. myregistry.azurecr.io/notify:1.2.3).')
param image string

@description('Name of the single container in the app template. Defaults to the service name; override only to match an existing container name on an import.')
param containerName string = service

@description('Ingress target port the container listens on.')
param targetPort int = 8080

@description('Whether ingress is reachable from outside the environment.')
param externalIngress bool = true

@description('Ingress transport (auto / http / http2 / tcp).')
@allowed([
  'auto'
  'http'
  'http2'
  'tcp'
])
param transport string = 'auto'

@description('Allow plain-HTTP ingress (no TLS redirect). Keep false — the environment terminates TLS.')
param allowInsecure bool = false

@description('Minimum replica count for the single container.')
@minValue(0)
param minReplicas int = 1

@description('Maximum replica count for the single container.')
@minValue(1)
param maxReplicas int = 3

@description('CPU cores allocated to the container (Container Apps allowed values, e.g. 0.25, 0.5, 1.0).')
param cpu string = '0.5'

@description('Memory allocated to the container (e.g. 1.0Gi).')
param memory string = '1.0Gi'

@description('Container environment variables. Each entry is { name, value } or { name, secretRef } — secretRef points at a `secrets` entry by name (never a literal value, D7).')
param envVars array = []

@description('Container App secrets, sourced from Key Vault by URI via the system-assigned identity. Each entry is { name, identity: \'system\', keyVaultUrl }. NO literal secret values (D7 / invariant 91).')
param secrets array = []

@description('Private registries the app pulls images from. Each entry is { server, identity: \'system\' } — image pull authenticated by the system-assigned managed identity (AcrPull granted by the consumer).')
param registries array = []

@description('KEDA scale rules (e.g. an azureQueue depth trigger). Empty = replica-count bounds only.')
param scaleRules array = []

var name = 'ca-hd-${service}-${env}'

resource containerApp 'Microsoft.App/containerApps@2025-07-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: secrets
      registries: registries
      ingress: {
        external: externalIngress
        targetPort: targetPort
        transport: transport
        allowInsecure: allowInsecure
      }
    }
    template: {
      containers: [
        {
          name: containerName
          image: image
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: envVars
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules
      }
    }
  }
}

@description('Principal ID of the Container App system-assigned managed identity. Grant RBAC (AcrPull, Key Vault, App Configuration, etc.) to this.')
output principalId string = containerApp.identity.principalId

@description('Fully-qualified ingress domain of the Container App.')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('The Container App resource name.')
output name string = containerApp.name
