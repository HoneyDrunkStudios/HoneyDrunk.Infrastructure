@description('Existing shared Service Bus namespace. This module never changes namespace settings.')
param namespaceName string

@description('Private queue name agreed by publisher and consumer.')
param queueName string

resource namespace 'Microsoft.ServiceBus/namespaces@2026-01-01' existing = {
  name: namespaceName
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2026-01-01' = {
  parent: namespace
  name: queueName
  properties: {
    lockDuration: 'PT1M'
    maxDeliveryCount: 10
    maxSizeInMegabytes: 1024
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    requiresDuplicateDetection: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enablePartitioning: false
    enableBatchedOperations: true
  }
}

@description('Queue resource ID for separately approved entity-scoped sender/receiver grants.')
output id string = queue.id
