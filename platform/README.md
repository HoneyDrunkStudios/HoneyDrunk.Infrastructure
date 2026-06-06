# platform/

The **shared-foundation** layer (ADR-0077 D2, introduced by the 2026-06-02
amendment). Resources here are owned by **no single Node** — they are the shared
substrate that per-Node leaf templates build on.

**Owns:**
- The shared **Container Apps Environment** (`cae-hd-{env}`, invariant 35).
- The shared **container-image ACR** (`acrhdshared{env}`, invariant 35 — the
  only ACR; there is no Bicep registry).
- The shared **Log Analytics** workspace (`log-hd-shared-{env}`).
- The shared **Service Bus** namespace (`sb-hd-shared-{env}`).
- Shared **networking** (VNet / subnets / private DNS), if/when introduced.

**Status:** authored (ADR-0077 packet 14). `platform/main.bicep` composes the
shared resources from the per-concern modules; `platform/parameters.{env}.bicepparam`
supply per-env values.

## Shared-foundation resources

`platform/main.bicep` (`targetScope = 'resourceGroup'`) composes four modules,
in dependency order:

| # | Resource | Name | Module |
| - | -------- | ---- | ------ |
| 1 | Log Analytics workspace | `log-hd-shared-{env}` | `../modules/observability/logAnalyticsWorkspace.bicep` |
| 2 | Container Apps Environment | `cae-hd-{env}` | `../modules/compute/containerAppEnvironment.bicep` |
| 3 | container-image ACR | `acrhdshared{env}` | `../modules/data/containerRegistry.bicep` |
| 4 | Service Bus namespace | `sb-hd-shared-{env}` | `../modules/messaging/serviceBusNamespace.bicep` (`service: 'shared'`) |

The Log Analytics workspace is declared **first** because the Container Apps
Environment (and per-Node diagnostics) reference its `id`.

### Logging is keyless (D7)

The Container Apps Environment routes app + system logs via the `azure-monitor`
destination plus a child `Microsoft.Insights/diagnosticSettings` resource that
references the workspace **by resource ID**. It deliberately does NOT use the
`log-analytics` destination, which would require the Log Analytics
`customerId` + `sharedKey` pair — `sharedKey` is a secret and is barred from
templates (ADR-0077 D7 / invariant 91). The shared key is likewise never emitted
as a workspace output.

The image ACR sets `adminUserEnabled: false`: consumers pull via managed
identity + `AcrPull` RBAC, so no admin credential exists to leak.

## Exports resource IDs — not hand-pasted ARM strings

`platform/main.bicep` exports every shared resource's ID as a deployment output:

- `logAnalyticsWorkspaceId`
- `containerAppEnvironmentId`
- `containerRegistryId`
- `containerRegistryLoginServer`
- `serviceBusNamespaceId`

Per-Node leaf templates under [`../nodes/`](../nodes) reference those exported
IDs, closing the gap the original ADR had (where Nodes consumed shared resources
via hand-pasted ARM resource IDs). **The exported IDs are the contract** — never
copy a raw `/subscriptions/.../providers/...` string into a Node's param file.

## Resource-group model

- **`rg-hd-platform-{env}`** (per-environment) — holds the per-env shared
  resources (`cae-hd-{env}`, `acrhdshared{env}`, `log-hd-shared-{env}`,
  `sb-hd-shared-{env}`). This is the deploy target for
  `platform/main.bicep` + `parameters.{env}.bicepparam`.
- **`rg-hd-platform-shared`** (environment-agnostic) — reserved for truly
  env-agnostic shared substrate (if/when any is introduced). Nothing in this
  packet deploys here; it is the documented home from the dead packet-02 RG
  decision that migrated into this layer.

## Grandfather posture (ADR-0077 D6)

The existing live `dev` platform resources — `acrhdshared{dev}` and `cae-hd-dev`
provisioned by the prior portal walkthroughs — are **not recreated**. Packet 14's
template is authored to *match* them, so adoption is a **no-op import**, not a
recreate:

1. Run `az deployment group what-if --resource-group rg-hd-platform-dev
   --parameters platform/parameters.dev.bicepparam` **before** any apply.
2. `what-if` must report **zero changes** against the running resources. If it
   reports changes, the **template is wrong, not the cloud** — reconcile the
   template to match, then re-run `what-if`.
3. Only after a clean (no-op) `what-if` is the first apply gated through (the
   `deploy.yml` caller + ADR-0033 environment approval).

The export → decompile → reconcile → adopt import procedure lives in **packet 17
(the import playbook)** — cross-reference it for the full grandfather workflow.
Resources that do NOT yet exist (e.g. staging/prod platform resources, or the
shared workspace if not yet provisioned) are created on first deploy.

## Deploying

Use the repo's [`deploy.yml`](../.github/workflows/deploy.yml) `workflow_dispatch`
caller with `target: platform` + the chosen `env`. It resolves
`platform/main.bicep` + `platform/parameters.{env}.bicepparam` +
`rg-hd-platform-{env}` and invokes the Actions `job-deploy-bicep.yml` behind the
ADR-0033 environment approval gate (prod requires reviewers). The deploy runs a
`bicep build` + `lint` + `what-if` preflight before apply.

Modules are consumed by local relative path (e.g.
`../modules/compute/containerAppEnvironment.bicep`) — no registry, no `br:`
references. See the [repo README](../README.md).
