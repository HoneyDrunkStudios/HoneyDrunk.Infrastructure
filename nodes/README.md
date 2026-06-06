# nodes/

Thin **per-Node leaf templates** (ADR-0077 D4, as amended). One subdirectory per
Node that provisions Azure resources, relocated here out of each Node's own repo
by the 2026-06-02 consolidation amendment.

## Shape

```
nodes/
  {node}/
    main.bicep                 # composes module references; declares the Node's resources
    parameters.dev.bicepparam  # per-environment parameter values
    parameters.staging.bicepparam
    parameters.prod.bicepparam
```

- **`main.bicep`** references the reusable modules in [`modules/`](../modules) by
  **local relative path from the leaf template**. From `nodes/{node}/main.bicep`
  (two levels deep) that is `module app '../../modules/compute/containerApp.bicep'`.
  It also consumes the [`platform/`](../platform) **exported resource IDs** —
  never hand-pasted ARM strings.
- **`parameters.{env}.bicepparam`** carries per-environment sizing / naming /
  regional pinning. Its `using` directive points at the sibling `main.bicep`, so
  deploys pass `--parameters parameters.{env}.bicepparam` with **no**
  `--template-file`.

## Cadence

Leaf templates land **per Node, at each Node's next significant infrastructure
touchpoint** (ADR-0077 D6) — scoped by that Node's standup ADR, not by the
ADR-0077 initiative. New infrastructure goes through Bicep from day one;
existing infrastructure is imported opportunistically (see the import playbook,
ADR-0077 packet 17).

Deploys run via `HoneyDrunk.Actions/.github/workflows/job-deploy-bicep.yml` on
the infra repo's own cadence, decoupled from application release tags.

The leaf-template **scaffold pattern** (the canonical structure to copy) is
documented separately as ADR-0077 packet 15.

No registry, no `br:` references — see the [repo README](../README.md).
