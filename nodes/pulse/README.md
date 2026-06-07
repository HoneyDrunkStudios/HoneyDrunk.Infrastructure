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

Manual `workflow_dispatch` via `.github/workflows/deploy.yml`.

### Steady state (app already exists)

```text
env=dev  target=node  node=pulse  mode=plan     # what-if dry run, review
env=dev  target=node  node=pulse  mode=apply    # deploy
```

### Brand-new / from-scratch — TWO passes (system-MI bootstrap)

A system-assigned-MI app that pulls a **private** image + resolves **Key Vault**
secret refs **cannot deploy in one pass**: the first revision needs AcrPull + Key
Vault Secrets User, those grants need the MI, the MI needs the app, and the app
blocks on the revision — deadlock (`Operation expired`). So a fresh deploy runs
twice:

```text
# Pass 1 — bootstrap: public placeholder image, no registry/secret wiring, but
# the role assignments ARE created. First revision goes healthy with zero RBAC.
env=dev  target=node  node=pulse  mode=apply  bootstrap=true   (checkbox checked)

# Pass 2 — real: private image + secrets + registry. RBAC now exists, so the
# revision pulls the real image and resolves the secret refs.
env=dev  target=node  node=pulse  mode=apply  bootstrap=false  (checkbox unchecked)
```

The `bootstrap` toggle overrides the leaf's `bootstrap` param via the deploy
workflow's `additional-parameters` passthrough. The role-assignment names fold in
the MI principalId, so pass 2 (and every later deploy) is idempotent.

### Environment is immutable — migration is delete + recreate

A Container App's `managedEnvironmentId` cannot change. Moving Pulse to a
different `cae-hd-<env>` requires **deleting the old `ca-hd-pulse-<env>` first**,
then the two-pass from-scratch deploy above (brief dev downtime).

## Image ownership

`image` is set in the param file and matches the image live at migration time.
Pulse has no CD step that updates the Container App image today, so infra owning
the image is conflict-free. When Pulse CD gains image promotion, the
image-ownership boundary (infra vs app CD) needs its own decision.
