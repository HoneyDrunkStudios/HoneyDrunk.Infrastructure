# nodes/pulse — HoneyDrunk.Pulse Node leaf template

The first Node leaf template (ADR-0077). Deploys the **Pulse observability
collector** Container App into `rg-hd-pulse-<env>`, joined to the **shared**
Container Apps Environment (`cae-hd-<env>`) in `rg-hd-platform-<env>`.

## What it deploys

| Resource | Owner | Notes |
|----------|-------|-------|
| `ca-hd-pulse-<env>` | this template | system-assigned MI, Multiple revisions, external ingress `:8080`, KEDA-less (replica bounds 0–10) |
| AcrPull on `acrhdshared<env>` | this template | cross-RG grant (platform RG) so the MI can pull its image |
| App Configuration Data Reader on `appcs-hd-shared<env>` | this template | cross-RG grant (platform RG) |
| Key Vault Secrets User on `kv-hd-pulse-<env>` | this template | resource-scoped, in-RG — resolves the `PostHog--ApiKey` / `Sentry--Dsn` references |

## What it consumes (existing — not managed here)

- `cae-hd-<env>`, `acrhdshared<env>`, `appcs-hd-shared-<env>` — shared foundation
  in `rg-hd-platform-<env>` (provisioned by `platform/`), referenced by
  convention name, no hand-pasted ARM IDs.
- `kv-hd-pulse-<env>` — the Node's Key Vault, referenced for its secret URIs.
  Its **secret values are not IaC** (D7). Adopting the vault resource itself into
  IaC (the `keyVault` module) is a tracked follow-up.

## Deploy

Manual `workflow_dispatch` via `.github/workflows/deploy.yml`:

```
env=dev  target=node  node=pulse  mode=plan    # what-if dry run, review
env=dev  target=node  node=pulse  mode=apply   # deploy
```

### Environment is immutable — migration is delete + recreate

A Container App's `managedEnvironmentId` cannot change. Moving Pulse from an old
environment to `cae-hd-<env>` requires **deleting the old `ca-hd-pulse-<env>`
first**, then applying this template (brief dev downtime). On first apply the
system MI is created, then its RBAC — the first revision may briefly fail to pull
its image / resolve secrets until the role assignments propagate, then self-heals
(or force it with `az containerapp revision restart`).

## Image ownership

`image` is set in the param file and matches the image live at migration time.
Pulse has no CD step that updates the Container App image today, so infra owning
the image is conflict-free. When Pulse CD gains image promotion, the
image-ownership boundary (infra vs app CD) needs its own decision.
