# modules/messaging

Per-concern Bicep modules for **messaging** (ADR-0077 D2).

**Owns:** Service Bus namespaces, topics, subscriptions, queues, Event Grid
topics.

**Example resources:** `serviceBusNamespace`, `serviceBusTopic`,
`eventGridTopic`.

**Status:** first module set authored (ADR-0077 packet 13) ships
`serviceBusNamespace`. Per-Node topics/subscriptions/queues land at each Node's
messaging touchpoint (ADR-0028); other messaging modules land when a consumer
first needs them.

**Consumed by** local relative path — no registry, no `br:` references (see the
[repo README](../../README.md)).

---

## `serviceBusNamespace.bicep`

`Microsoft.ServiceBus/namespaces@2024-01-01`. Produces `sb-hd-<service>-<env>`,
`Standard` sku (param-defaulted; tier mirrors the sku name).

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(13)`; feeds `sb-hd-<service>-<env>`. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags; applied to every resource. |
| `sku` | string | `'Standard'` | `@allowed('Basic','Standard','Premium')`. |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `id` | string | Resource ID. |
| `name` | string | Resource name. |
| `endpoint` | string | `serviceBusEndpoint` (`https://<name>.servicebus.windows.net:443/`). |

### Secret discipline (ADR-0077 D7 / invariant 91)

No raw secret params, and no SAS keys output. Consumers connect via **managed
identity + RBAC**; SAS connection strings, if ever required, live in Key Vault
and are referenced by URI — never templated or output.

### Reference example

```bicep
module bus '../../modules/messaging/serviceBusNamespace.bicep' = {
  name: 'notifyBus'
  params: {
    service: 'notify'
    env: env
    tags: tags
  }
}
```
