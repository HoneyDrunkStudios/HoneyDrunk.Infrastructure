@description('Linux single-container Web App. Invoke only for reviewed bootstrap/configuration maintenance; CD owns subsequent images.')
param name string
param location string = resourceGroup().location
param tags object
param planId string
param subnetId string
param image string
param enabled bool = true
param port int = 8080
param healthPath string = '/health'
param appSettings array = []

resource app 'Microsoft.Web/sites@2024-11-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: planId
    enabled: enabled
    httpsOnly: true
    clientAffinityEnabled: false
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: subnetId
    // Route application traffic, including public SQL service-endpoint addresses,
    // through integration. Image pulls and MI acquisition retain their public route.
    outboundVnetRouting: {
      applicationTraffic: true
      allTraffic: false
      imagePullTraffic: false
    }
    siteConfig: {
      linuxFxVersion: 'DOCKER|${image}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      healthCheckPath: healthPath
      appSettings: concat([
        { name: 'WEBSITES_PORT', value: string(port) }
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE', value: 'false' }
        { name: 'WEBSITE_WARMUP_PATH', value: healthPath }
        { name: 'WEBSITE_WARMUP_STATUSES', value: '200' }
        { name: 'WEBSITES_CONTAINER_START_TIME_LIMIT', value: '600' }
        { name: 'WEBSITE_HEALTHCHECK_MAXPINGFAILURES', value: '2' }
      ], appSettings)
    }
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: app
  name: 'ftp'
  properties: { allow: false }
}
resource scmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: app
  name: 'scm'
  properties: { allow: false }
}
output principalId string = app.identity.principalId
output fqdn string = app.properties.defaultHostName
