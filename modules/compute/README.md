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
| `targetPort` | int | `8080` | Ingress target port. |
| `externalIngress` | bool | `true` | External vs environment-internal ingress. |
| `minReplicas` | int | `1` | |
| `maxReplicas` | int | `3` | |
| `cpu` | string | `'0.5'` | CPU cores (parsed via `json()`). |
| `memory` | string | `'1.0Gi'` | |

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
