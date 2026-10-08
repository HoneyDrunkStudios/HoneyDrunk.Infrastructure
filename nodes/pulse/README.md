# nodes/pulse — HoneyDrunk.Pulse

The Pulse observability collector lives in `rg-hd-pulse-<env>` and joins the
shared `cae-hd-<env>` in `rg-hd-platform-<env>`. This leaf maintains the app's
system-assigned identity grants: AcrPull and App Configuration Data Reader in
the platform resource group, and Key Vault Secrets User in the Pulse resource
group. The grants are resource-group-scoped. Key Vault secret **values** and
App Configuration key-values remain outside this template.

## Ownership contract

Pulse application CD owns release images, candidate revisions, promotion and
rollback. Normal Infrastructure deploys now **reference the existing Container
App** and reconcile RBAC only. They do not PUT the app, replay a historical image,
change ingress/traffic, or create a revision. The old checked-in release image
has been removed from `parameters.dev.bicepparam`. The legacy `image` template
parameter is still accepted for compatibility, but cannot enable an app write
and cannot substitute for the required `appUpdate.image` during maintenance.

This is a deliberate change to Pulse's default behavior. `bootstrap=false` no
longer means "replace the app with the real image". It means "use the existing
app" unless an explicit `appUpdate` is supplied. The shared Container App module
retains its defaults for other consumers.

| Operation | Template parameters | App write / traffic |
| --- | --- | --- |
| Steady state | `bootstrap=false`, `appUpdate=null` (defaults) | Existing-app reference only; no app configuration write |
| New app bootstrap | `bootstrap=true`, no `appUpdate` | Public placeholder, revision `ca-hd-pulse-<env>--bootstrap`, 100% explicitly pinned to that revision |
| Initialization / reviewed maintenance | `bootstrap=false`, explicit `appUpdate={image, trafficRevision}` | Approved image/configuration; 100% retained on the explicitly named known-good revision; new candidate gets no production traffic |

Use **incremental deployments only**, as the reusable Bicep workflow does by
default. Do not use complete-mode deployment or resource-deleting stack options:
omitted/conditional resources must not be interpreted as resources to delete.

## Dispatch inputs

Manual `.github/workflows/deploy.yml` dispatches keep the existing `env`,
`target=node`, `node=pulse`, `mode=plan|apply`, and `bootstrap` inputs. New inputs:

- `manage-app` defaults to false. Set true only for approved initialization or
  maintenance, after following the procedure below
- `app-image` is the exact approved image reference, preferably an immutable
  digest. It is required with `manage-app`
- `traffic-revision` is the full, verified revision name to **retain at 100%**,
  such as `ca-hd-pulse-dev--<known-good-suffix>`. It is required with `manage-app`

The resolver rejects missing fields, another app/environment's revision,
`latest`, shell/whitespace injection, stray update inputs, and bootstrap combined
with maintenance **before Azure authentication**. It passes one compact
`appUpdate` JSON object through the reusable workflow's `additional-parameters`.
The object is sealed in Bicep and both fields must be nonempty. Other Node
consumers do not receive Pulse-only parameters. Only the dev Pulse parameter
file currently exists; other environments fail closed until explicitly added.

These checks validate intent and syntax, **not live health or freshness**. The
workflow does not discover a serving revision, select the newest/active
revision, acquire a cross-repository lock, or prove that an operator's snapshot
is current. The manual coordination and verification below are mandatory.
Direct template users must follow the same procedure and never combine
`bootstrap` with `appUpdate`.

## Existing app: normal Infrastructure changes

Dispatch `env=dev target=node node=pulse mode=plan`, with bootstrap and manage-app
both false. Review the what-if: the app must not be modified or deleted. Apply
only after the usual environment approval. This reconciles RBAC, not app tags,
scaling, secrets, registry wiring or container configuration. To change those app
settings, use the explicit maintenance path below.

## Brand-new app: bootstrap, initialize, then promote

A new system-assigned-MI app cannot immediately pull its private image or resolve
Key Vault secrets: RBAC needs the app identity, but creating a healthy private
revision needs RBAC. The bootstrap pass breaks that dependency.

1. Separately authorize this Azure operation and verify the app does not exist.
   Never run bootstrap against an existing serving app. Keep Pulse CD quiesced
   throughout bootstrap and initialization
2. Plan and apply with `bootstrap=true`, `manage-app=false`. The pinned public
   placeholder listens on port 80, requires no registry/secret wiring, and
   permits identity grants to be created. Verify the grants have propagated and
   the explicit `ca-hd-pulse-<env>--bootstrap` revision is healthy
3. Plan initialization with `bootstrap=false`, `manage-app=true`, the approved
   private `app-image`, and `traffic-revision=ca-hd-pulse-<env>--bootstrap`. Review
   registry and Key Vault references, image, resource settings and named traffic
   before applying. The configuration revision is not promoted by IaC
4. **Initialization is not zero-downtime.** Ingress targetPort is app-scoped and
   changes from 80 to 8080. The pinned placeholder still listens on 80, so its
   public route can stop working before promotion. This path is only for a new
   app, not a serving production migration. The revision-specific candidate
   endpoint must be checked on the real port before traffic is promoted
5. Use the approved application CD process to create/check a candidate and
   promote only after its revision-specific readiness/smoke checks pass. Verify
   the public endpoint and exact named 100% traffic. Thereafter leave both
   bootstrap and manage-app false for normal Infrastructure deploys

## Existing app: approved initialization/maintenance or legacy migration

Preparing or merging this change does not alter Azure or repair current routing.
Any live migration, traffic pin, workflow retry or apply requires separate
approval. Do not delete/recreate an app to adopt this contract.

1. Establish an exclusive maintenance window: pause competing CD dispatches,
   scheduled releases and manual app changes, and wait for in-flight work to
   finish. GitHub concurrency groups do **not** lock across repositories
2. Read and record the complete current app configuration, traffic rules/labels,
   active revisions, known-good revision's exact image, and rollback target.
   Inspect readiness and revision-specific health. A revision being active or
   latest is not evidence it is known-good. Never select a newer failed candidate
3. If traffic still uses `latestRevision: true`, obtain approval for a separate
   one-time pin to the verified known-good revision. Verify the resulting named
   100% rule with no latest selector. Do not retry application CD until this is
   correct. A split/canary state or labels need deliberate handling: this leaf's
   maintenance update replaces traffic with a single named 100% entry and does
   not preserve arbitrary splits/labels
4. For actual configuration maintenance, supply `manage-app=true`, the exact
   approved image and verified serving `traffic-revision`. Do not copy an old
   repo image. Review the full what-if, including all app-scoped ingress,
   secrets, registries and all template settings. App-scoped changes affect the
   serving revision even when traffic remains pinned
5. Immediately before an approved apply, re-read image, traffic and revision
   state under the same exclusive window. If they changed since review, stop
   and regenerate the plan; do not apply a stale snapshot. Never combine this
   path with bootstrap. Newly created revisions must remain at zero public
   traffic. Verify named traffic and the serving endpoint after the apply
6. Promote any candidate only through approved readiness/smoke checks and the
   application CD traffic switch. Record the resulting known-good revision and
   return Infrastructure to the default existing-app path before unpausing CD

### Rollback

Before promotion, keep the captured known-good revision active and pinned. A
failed candidate must not be promoted; restore any failed **app-scoped** settings
from the captured configuration under approval, since a traffic rollback alone
does not undo ingress, registry or secret changes. After promotion, an approved
rollback explicitly assigns 100% to the verified prior known-good revision and
checks the serving endpoint. Never rollback to `latest`, rerun bootstrap, or
reapply the removed historical image. Restore labels/splits deliberately if
those were part of the pre-maintenance state.

The Container Apps Environment is immutable for an existing app. Moving to a
different environment is a separate, approved migration with a downtime/rollback
plan; it is not part of this contract repair.

## Offline verification

Install the official Bicep CLI v0.48.1 (also pinned for lint and deployment),
then install the test-only Azure CLI package in a virtual environment:

```sh
python3 -m venv .venv-tests
.venv-tests/bin/python -m pip install azure-cli==2.91.0
BICEP_BIN=/path/to/bicep .venv-tests/bin/python -m unittest discover -s tests -v
bicep lint nodes/pulse/main.bicep
bicep lint modules/compute/containerApp.bicep
```

Tests exercise real dispatch resolution and compile the templates/parameter
files to inspect default ownership, conditional app creation, typed maintenance
inputs, explicit named traffic and backward-compatible module defaults. They
also run Azure CLI 2.91.0's actual deployment parameter parser with the resolver's
inline override and the real parameter file, asserting that `appUpdate` reaches
the compiled deployment parameters as the exact object. Tests prohibit network
authentication and resource calls; they never invoke a deployment or what-if.
This proves local toolchain interpretation, not service-side acceptance. Live
what-if/apply, Container Apps behavior and smoke tests remain separately approved
deployment verification.
