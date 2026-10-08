# modules/compute

Per-concern Bicep modules for **compute** (ADR-0077 D2).

**Owns:** the Container Apps environment, Container Apps, Container Apps Jobs,
Function Apps.

**Example resources:** `containerAppEnvironment`, `containerApp`,
`containerAppJob`.

**Status:** first module set authored (ADR-0077 packet 13). `containerApp` is
one of the first modules — every Node provisions a Container App.

**Consumed by** local relative path — no registry, no `br:` references (see the
[repo README](../../README.md)).

---

## `containerApp.bicep`

`Microsoft.App/containerApps@2025-07-01`. Produces `ca-hd-<service>-<env>`
(invariant 34) with a **system-assigned managed identity** (invariant 34) in
**Multiple revision mode** (invariant 36). Consumes the shared Container Apps
Environment by resource ID — it does **not** create the environment (that is
`platform/`-owned, packet 14).

### Parameters

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `service` | string | — | `@maxLength(13)`; feeds `ca-hd-<service>-<env>`. |
| `env` | string | — | `@allowed('dev','staging','prod')`. |
| `location` | string | `resourceGroup().location` | |
| `tags` | object | — | Required Grid tags (`hd:node`, `hd:env`, `hd:owner`, `hd:cost-center`, `hd:dr-tier`, `hd:adr`); applied to every resource. |
| `containerAppEnvironmentId` | string | — | Resource ID of the shared `cae-hd-<env>`. Not created here. |
| `image` | string | — | Container image reference. |
| `containerName` | string | `service` | Single-container name; override only to match an existing name on import. |
| `traffic` | trafficWeight[] | `[{ latestRevision: true, weight: 100 }]` | Explicit ingress rules. Legacy default retained for compatibility; CD-managed consumers must pass named revisions. |
| `revisionSuffix` | string | `''` | Optional deterministic revision suffix. Empty omits the property; do not reuse for a changed template. |
| `targetPort` | int | `8080` | Ingress target port. |
| `externalIngress` | bool | `true` | External vs environment-internal ingress. |
| `transport` | string | `'auto'` | `@allowed('auto','http','http2','tcp')`. |
| `allowInsecure` | bool | `false` | Plain-HTTP ingress; keep false (env terminates TLS). |
| `minReplicas` | int | `1` | |
| `maxReplicas` | int | `3` | |
| `cpu` | string | `'0.5'` | CPU cores (parsed via `json()`). |
| `memory` | string | `'1.0Gi'` | |
| `envVars` | array | `[]` | Container env: `{ name, value }` or `{ name, secretRef }` — never literal secret values (D7). |
| `secrets` | array | `[]` | Key Vault references: `{ name, identity: 'system', keyVaultUrl }`. No literal secret values (D7 / invariant 91). |
| `registries` | array | `[]` | Private registries: `{ server, identity: 'system' }` — pull authed by the system MI (AcrPull granted by the consumer). |
| `scaleRules` | array | `[]` | KEDA scale rules (e.g. an azureQueue depth trigger). |

### Outputs

| Output | Type | Notes |
| --- | --- | --- |
| `principalId` | string | System-assigned MI principal ID — grant AcrPull / Key Vault / App Configuration RBAC to it. |
| `fqdn` | string | Ingress FQDN. |
| `name` | string | Resource name. |

### Secret discipline (ADR-0077 D7 / invariant 91)

No raw secret params. The container reaches Key Vault, App Configuration, ACR,
etc. via its **system-assigned managed identity** + RBAC — no connection strings
or registry credentials are templated.

### Reference example

```bicep
module app '../../modules/compute/containerApp.bicep' = {
  name: 'identityApp'
  params: {
    service: 'identity'
    env: env
    tags: tags
    containerAppEnvironmentId: caeId      // from platform/
    image: 'myacr.azurecr.io/identity:1.0.0'
    targetPort: 8080
  }
}
```

### Traffic ownership

The module is a full Container App write, not a patch. It applies the caller's
image, configuration and traffic rules. Its historical latest-revision default
is kept for unrelated consumers; it is unsafe for a CD process that creates
zero-traffic candidates unless the caller explicitly overrides traffic. For a
CD-managed app, use a named known-good revision (`latestRevision: false`,
`revisionName: '<app>--<known-good>'`, `weight: 100`) during a reviewed update,
and avoid calling this module in steady state when CD owns the app.

[Pulse's lifecycle contract](../../nodes/pulse/README.md) demonstrates an
existing-resource default, named bootstrap and explicit maintenance. A traffic
parameter alone does not preserve concurrent CD updates or app-scoped settings.
