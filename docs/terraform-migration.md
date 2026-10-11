# Terraform migration and adoption

The October 10 Bicep-to-Terraform source migration merged as Infrastructure PR #16.
The old Bicep dispatcher remains retired. Its source survives in Git history.

On October 11 the founder broadened ownership to all existing development Azure
infrastructure and linked identity configuration. [The current adoption contract](terraform-adoption.md)
supersedes the earlier Pulse/Notify/automation/directory exclusions. Existing
resources are imported with exact IDs; their names, tags, SKU, access, credentials
and data are preserved. The former Pulse grant-only root has one successor owner
for its grants: `platform/access`.

## Separately approved deployment completed October 11

`platform/app-network`, `platform/sql`, `platform/sql-access`, `nodes/identity`,
`nodes/identity-data` and `nodes/identity-vault` now have live resources and Azure
state. Initialize their exact existing backends from the
[state map](terraform-adoption.md#state-and-source-boundaries); never treat them as
empty first-creation targets. The customer-applications root also owns the new
public Graph certificate while preserving the previous certificate.

Identity's B1 app/plan and Entra-only SQL server/Basic database are in Central US.
The app uses scoped public-egress SQL rules without VNet integration. The deployed
East US 2 app network is preserved along with the registry, vault and other
existing resources. Workstation access is an explicitly selected single-IP rule.
The app is serving after separately approved schema, permission, credential and
runtime setup; releases own image/settings/enabled state/health path.

Only `nodes/identity-messaging` remains an unexecuted proposal. Lifecycle queues
and consumer activation, automated release identities, native product acceptance
and Azure backup restoration remain outstanding. Source publication grants no
new deployment authority. B1 has no slots. Coordinate writers and review exact
plans before subsequent infrastructure, runtime, SQL or credential changes.
No automatic apply is enabled here.

The legacy required status `Bicep Lint / Bicep Lint` is still a fail-closed aggregate
of Terraform validation and secret scanning. Do not change branch protection or
restore retired Grid Review. Explicit code review and current exact-head review
remain required by the studio working agreement.
