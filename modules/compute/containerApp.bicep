// =============================================================================
// modules/compute/containerApp.bicep  (ADR-0077 packet 13)
// Microsoft.App/containerApps — one Container App per Node (invariant 34).
// System-assigned managed identity (invariant 34), Multiple revision mode
// (invariant 36). Consumes the shared Container Apps Environment by ID; does
// NOT create it. No raw secret params (D7 / invariant 91).
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

@description('Ingress target port the container listens on.')
param targetPort int = 8080

@description('Whether ingress is reachable from outside the environment.')
param externalIngress bool = true

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
      ingress: {
        external: externalIngress
        targetPort: targetPort
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: service
          image: image
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
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
