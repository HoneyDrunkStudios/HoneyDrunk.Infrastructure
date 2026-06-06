# modules/messaging

Per-concern Bicep modules for **messaging** (ADR-0077 D2).

**Owns:** Service Bus namespaces, topics, subscriptions, queues, Event Grid
topics.

**Example resources:** `serviceBusNamespace`, `serviceBusTopic`,
`eventGridTopic`.

**Status:** empty-state. Module bodies land when a consumer first needs them.
The shared Service Bus namespace is a `platform/` resource (ADR-0077 packet 14);
per-Node topics/subscriptions/queues land at each Node's messaging touchpoint
(ADR-0028).

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module topic '../../modules/messaging/serviceBusTopic.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
