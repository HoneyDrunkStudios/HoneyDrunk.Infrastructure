# modules/observability

Per-concern Bicep modules for **observability** (ADR-0077 D2).

**Owns:** Application Insights, Log Analytics, Action Groups, Alerts.

**Example resources:** `applicationInsights`, `logAnalyticsWorkspace`,
`actionGroup`.

**Status:** empty-state. Module bodies land in ADR-0077 packet 13 (the first
six-concern module set ships `applicationInsights`). The shared Log Analytics
workspace is a `platform/` resource (ADR-0077 packet 14); per-Node App Insights
components (ADR-0040 / ADR-0045) consume it.

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module appInsights '../../modules/observability/applicationInsights.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
