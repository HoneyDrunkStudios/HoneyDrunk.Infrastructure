# modules/observability

Per-concern Bicep modules for **observability** (ADR-0077 D2).

**Owns:** Application Insights, Log Analytics, Action Groups, Alerts.

**Example resources:** `applicationInsights`, `logAnalyticsWorkspace`,
`actionGroup`.

**Status:** first module set authored (ADR-0077 packet 13) ships
`applicationInsights`. The shared Log Analytics workspace is a `platform/`
resource (ADR-0077 packet 14); per-Node App Insights components (ADR-0040 /
ADR-0045) consume it by ID.

**Consumed by** local relative path — no registry, no `br:` references (see the
[repo README](../../README.md)).

---

## `applicationInsights.bicep`

`Microsoft.Insights/components@2020-02-02`. Produces `appi-hd-<service>-<env>`,
**workspace-based** (`kind: 'web'`, `Application_Type: 'web'`,
`WorkspaceResourceId: <logAnalyticsWorkspaceId>`). Consumes the shared Log
Analytics workspace by ID — it does **not** create the workspace.

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(13)`; feeds `appi-hd-<service>-<env>`. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags; applied to every resource. |
| `logAnalyticsWorkspaceId` | string | — | Shared workspace ID (required for workspace-based App Insights). Not created here. |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `id` | string | Resource ID. |
| `name` | string | Resource name. |

> **No connection string / instrumentation key outputs.** Per ADR-0040 and
> ADR-0077 D7, the App Insights connection string and instrumentation key are
> Vault-held credentials and are **not** exposed as deployment outputs (which
> would surface them in `az deployment ... outputs` and CI logs). Consumers
> obtain the connection string via the Key Vault reference pattern (store it as
> a `keyVaultSecret`, inject by URI) or via Entra-based ingestion auth. The
> module takes no raw secret params (invariant 91).

### Reference example

```bicep
module appInsights '../../modules/observability/applicationInsights.bicep' = {
  name: 'notifyInsights'
  params: {
    service: 'notify'
    env: env
    tags: tags
    logAnalyticsWorkspaceId: lawId        // from platform/
  }
}
```
