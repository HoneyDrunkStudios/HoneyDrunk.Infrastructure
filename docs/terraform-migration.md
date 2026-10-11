# Terraform migration and adoption

The October 10 Bicep-to-Terraform source migration merged as Infrastructure PR #16.
The old Bicep dispatcher remains retired. Its source survives in Git history.

On October 11 the founder broadened ownership to all existing development Azure
infrastructure and linked identity configuration. [The current adoption contract](terraform-adoption.md)
supersedes the earlier Pulse/Notify/automation/directory exclusions. Existing
resources are imported with exact IDs; their names, tags, SKU, access, credentials
and data are preserved. The former Pulse grant-only root has one successor owner
for its grants: `platform/access`.

## Proposed deployments remain separate

The unexecuted roots are `platform/app-network`, `platform/sql`,
`platform/sql-access`, `nodes/identity`, `nodes/identity-data`,
`nodes/identity-vault` and `nodes/identity-messaging`. Their design retains a
dedicated App Service VNet/subnet, shared Entra-only SQL server, separate Basic
Identity database, dedicated Linux B1 plan/stopped app, Identity vault and future
lifecycle queues. No CIDR, SQL administrator, publishing executor, image release,
queue activation or new service spend follows merely from adoption or merge.

Before deployment, review current prices, names, network choices, administration,
state containers/access, exact saved plans and recovery. Resource creation does
not authorize DACPAC publishing, contained SQL users, Graph permission changes,
consumer activation or a runtime release. B1 has no slots; retained-image rollback
requires a tested maintenance procedure. Coordinate all writers before real app
configuration or database schema changes. No automatic apply is enabled here.

The legacy required status `Bicep Lint / Bicep Lint` is still a fail-closed aggregate
of Terraform validation and secret scanning. Do not change branch protection or
restore retired Grid Review. Explicit code review and current exact-head review
remain required by the studio working agreement.
