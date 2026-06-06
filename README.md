# HoneyDrunk.Infrastructure

Infrastructure-as-Code for the HoneyDrunk Grid. **All** Bicep content for every
Azure resource the Grid provisions lives here, per [ADR-0077](https://github.com/HoneyDrunkStudios/HoneyDrunk.Architecture/blob/main/adrs/ADR-0077-infrastructure-as-code-bicep.md)
(amended 2026-06-02 to consolidate Bicep content into this single repo and drop
the cross-repo module registry).

The **pipeline** does not live here. The reusable deploy and lint workflows stay
in [`HoneyDrunk.Actions`](https://github.com/HoneyDrunkStudios/HoneyDrunk.Actions)
per [ADR-0012](https://github.com/HoneyDrunkStudios/HoneyDrunk.Architecture/blob/main/adrs/ADR-0012-grid-cicd-control-plane.md)
(Actions is the CI/CD control plane); this repo *consumes* them.

## Layout

| Directory | Owns |
|---|---|
| [`modules/`](./modules) | The seven per-concern reusable modules (networking, compute, identity, data, secrets, messaging, observability). The reusable building blocks. |
| [`platform/`](./platform) | Shared / foundational resources owned by no single Node: the shared Container Apps Environment, the shared image ACR (`acrhdshared{env}`), Log Analytics, the shared Service Bus namespace, networking. Exports resource IDs that Node templates consume. |
| [`nodes/{node}/`](./nodes) | Thin per-Node leaf templates (`main.bicep` + `parameters.{env}.bicepparam`). One per Node that provisions Azure resources. |

## Module references are local relative paths — there is no registry

Because `modules/`, `platform/`, and `nodes/` all live in one repo checkout,
modules are referenced by **local relative path**:

```bicep
module containerApp '../../modules/compute/containerApp.bicep' = { ... }
```

There is **no** Bicep registry, **no** `acrhdbicep`, **no** `bicep-publish.yml`,
**no** `modules/v{N}.{N}.{N}` SemVer tags, and **no** `br:` references. The
cross-repo module registry was dropped by the 2026-06-02 amendment — modules are
versioned by git history and resolved from the filesystem at `bicep build` time.

## Linting

A single root [`bicepconfig.json`](./bicepconfig.json) carries the
[ADR-0077 D3](https://github.com/HoneyDrunkStudios/HoneyDrunk.Architecture/blob/main/adrs/ADR-0077-infrastructure-as-code-bicep.md)
naming/tagging linter rules and governs all three subtrees via Bicep's
config-file resolution. PRs are gated by the `bicep lint` reusable workflow
(`HoneyDrunk.Actions/.github/workflows/job-bicep-lint.yml`), which fails on any
`error`-severity finding or `.bicepparam` validation error. See
[`.github/workflows/pr.yml`](./.github/workflows/pr.yml).

## Deploying

Deployment runs through the reusable
`HoneyDrunk.Actions/.github/workflows/job-deploy-bicep.yml` workflow (OIDC auth,
`bicep build` + `lint` + `what-if` preflight, then `az deployment ... create`).
Infrastructure deploys on its **own cadence, decoupled from application release
tags** — infra and application code rarely change together, and when they do,
two separate deploys is acceptable.

## Secrets

Bicep templates **never** contain secret values (ADR-0077 D7 / invariant 91).
Secrets are referenced by Key Vault URI / `keyVaultSecret`; `.bicepparam` files
carry non-secret configuration only; the OIDC deploy identity provisions
resources, it does not read secret values.
