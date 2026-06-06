# platform/

The **shared-foundation** layer (ADR-0077 D2, introduced by the 2026-06-02
amendment). Resources here are owned by **no single Node** — they are the shared
substrate that per-Node leaf templates build on.

**Owns:**
- The shared **Container Apps Environment** (`cae-hd-{env}`, invariant 35).
- The shared **container-image ACR** (`acrhdshared{env}`, invariant 35 — the
  only ACR; there is no Bicep registry).
- The shared **Log Analytics** workspace.
- The shared **Service Bus** namespace.
- Shared **networking** (VNet / subnets / private DNS), if/when introduced.

**Status:** empty-state. The `platform/` templates land in ADR-0077 packet 14.

## Exports resource IDs — not hand-pasted ARM strings

`platform/main.bicep` declares the shared resources and **exports their resource
IDs as deployment outputs**. Per-Node leaf templates under [`../nodes/`](../nodes)
reference those exported IDs, closing the gap the original ADR had (where Nodes
consumed shared resources via hand-pasted ARM resource IDs).

## Resource group

Per-environment shared resources live in `rg-hd-platform-{env}`. Environment-
agnostic shared substrate uses `rg-hd-platform-shared`.

## Grandfather posture (ADR-0077 D6)

The existing live `dev` platform resources (`acrhdshared{dev}`, `cae-hd-dev`,
etc.) are **not recreated**. Packet 14's template is authored to *match* them, so
adoption is verified as a no-op via `az deployment group what-if` — `what-if`
should report **zero changes** against the running resources. If it reports
changes, the template is wrong, not the cloud.

Modules are consumed by local relative path (e.g.
`../modules/compute/containerAppEnvironment.bicep`) — no registry, no `br:`
references. See the [repo README](../README.md).
