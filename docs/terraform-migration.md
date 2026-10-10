# Terraform migration and adoption

## Verified scope — October 10, 2026

Read-only Azure inventory on Nov inspected the `honeydrunk-dev` subscription,
resource/group lists, selected properties and diagnostics. It did not read keys
or secret values. No live Terraform plan, refresh, import, backend operation or
Azure mutation occurred. Absence here does not prove absence in other subscriptions.

| Observed live | Treatment |
| --- | --- |
| `rg-hd-platform-dev`: `log-hd-shared-dev`, `cae-hd-dev`, `acrhdshareddev`, `appcs-hd-shared-dev`, `sb-hd-shared-dev` | Adopt exact IDs only after approval; never recreate |
| `cae-hd-dev` diagnostics `diag-to-law` | Azure Monitor destination, console/system logs and AllMetrics; no VNet or workload profiles observed |
| Pulse app and vault in `rg-hd-pulse-dev` | Remain outside Terraform managed-resource ownership; app data source supplies MI |
| Notify resources, automation vault, service-health resources | Unrelated live resources; excluded |
| External ID directory in `rg-hd-identity-dev` | Directory only; not an Identity API deployment; excluded |

The shared workspace has PerGB2018/30-day retention, ACR is Basic and App
Configuration is developer. Service Bus is Standard/TLS 1.2 with local auth
enabled. Source preserves the observed setting; disabling SAS requires a separate
consumer/access review. All selected resources are in East US 2.

The proposed `sql-hd-shared-dev`, `sqldb-hd-identity-dev`, `vnet-hd-apps-dev`,
`asp-hd-identity-dev`, `app-hd-identity-dev` and `kv-hd-identity-dev` were absent.
No Terraform backend account was found. Notify storage is not repurposed.
Names still require availability checks; no CIDR, SQL administrator group, grants
or spending was approved. Test IDs and `10.240.*` ranges are synthetic fixtures.

## Source migration and related work

- Infrastructure [#13](https://github.com/HoneyDrunkStudios/HoneyDrunk.Infrastructure/pull/13)
  at `3f185fbf993a7eef51104de4db93a42d551bf25f` supplies the B1/VNet/shared SQL
  design and bootstrap/ownership safeguards translated here. Do not merge its
  older Bicep implementation on top of this replacement.
- Actions [#218](https://github.com/HoneyDrunkStudios/HoneyDrunk.Actions/pull/218)
  at `377f0431f4b9f69d982565be88ed9d7c135ab6f8` retains strict formatter fixes and
  protected App Service release/rollback. It is independent of Terraform validation
  and remains separate from Terraform validation. It is the runtime workflow source
  for its Identity consumer; source merge does not enable runtime deployment.
- Studio [#808](https://github.com/HoneyDrunkStudios/HoneyDrunk.Studio/pull/808)
  merged the related hosting/docket reconciliation. The public implementation
  and operational contracts are the runbooks in this repository; that documentation
  merge did not provision or adopt Azure resources.
- Identity application PR/check status is owned by its repository and merge
  coordinator. Terraform source readiness does not establish runtime readiness,
  Graph consent, credentials or permission for a SQL publisher.

## Source coverage and ownership changes

The active Bicep modules, parameter files, dispatcher and Bicep-only tests are
replaced. Git history preserves them. AzureRM modules cover Container Apps and
environments, plans/Web Apps, ACR, storage, role assignments, Service Bus/queues,
App Configuration, vaults, diagnostics, Insights, logs, networking and SQL.
AzureRM 5.9.0 supports the selected features; no AzAPI gap was found.

- Pulse's steady-state app is a **data source**: no app PUT, image, revision or
  traffic write. Only its three existing grants can be adopted, preserving exact
  assignment UUIDs and RG scopes. Its existing vault remains grandfathered.
  The reusable Container App module preserves immutable images and named serving
  traffic for a future approved maintenance composition; it is not invoked for
  live Pulse. Old bootstrap/maintenance switches are retired. Future KEDA/scaling
  profiles require a reviewed extension; current Pulse is HTTP-driven.
- Bicep `provision*`/null switches meant "skip writes." Terraform removal or
  `count = 0` means deletion, so these become independent durable state roots:
  network, SQL server, SQL access, Identity compute, database, vault and queues.
- SQL server/admin ownership remains platform-only; product roots own separate
  databases. Identity uses Basic/2 GiB/local backups/seven-day retention. SQL
  access is a separately approved subnet rule requiring the classic Microsoft.Sql
  endpoint. No Azure-services bypass, arbitrary IP firewall inputs, NAT or private
  endpoint is introduced. Executor/operator IP access remains unapproved.
- Identity compute is one Linux B1 worker and a stopped immutable placeholder.
  Image, settings, enabled state and health path are ignored after creation so
  normal IaC cannot replay CD/configuration-owned runtime values. See its README.
- New Identity vault source adds purge protection; no existing vault is changed.
  Queue source retains duplicate detection, dead-lettering, TTL and lock policies.
  Neither declares grants or activates consumers.
- Staging/prod parameter files are retired; executable roots reject non-dev
  environments. No live environment is changed. Resource groups are referenced,
  never implicitly created.

## Adoption sequence — requires separate approval

1. Approve/bootstrap the dedicated backend, identity scopes, network and recovery
   design in [terraform-state.md](terraform-state.md). None exists as a result
   of this source PR.
2. Freshly inventory exact IDs, tags, SKUs, child resources, diagnostics, identity,
   locks, app/runtime ownership and RBAC UUIDs without exposing secret values.
3. Freeze all writers for the selected scope. Removing the Bicep dispatcher does
   not stop in-flight jobs or older-ref workflows. Verify none remain queued or
   running; coordinate shared-platform changes with Pulse operations. App
   maintenance additionally freezes CD and operator writes.
4. Prepare private backend configuration and exact-ID import manifest for one
   root. Copy the committed provider lock into that root. Import **every** already
   existing declared resource before any apply; never create from an empty state
   and hope conflicts are harmless. Backend init/import can write state and need
   approval; they are not read-only discovery and must not run in PR jobs.
5. Review a confidential saved plan in a trusted session. Adoption must show
   **zero create/update/delete**. Defaults and computed fields can drift despite
   matching names. Resolve source mismatch first; replacements, SKU changes,
   access changes or deletes stop adoption. Never apply merely to clear drift.
6. Record addresses/IDs, versions, state lineage/serial, no-op evidence, reviewer
   and timestamp privately; publish only a sanitized summary. Pass approved IDs
   explicitly between roots instead of granting `terraform_remote_state` access
   to another root's entire snapshot.

| Root | Import address | Existing resource |
| --- | --- | --- |
| `platform` | `module.logs.azurerm_log_analytics_workspace.this` | `log-hd-shared-dev` |
| `platform` | `module.environment.azurerm_container_app_environment.this` | `cae-hd-dev` |
| `platform` | `module.environment_diagnostics.azurerm_monitor_diagnostic_setting.this` | Environment ID + `\|diag-to-law` (provider import format) |
| `platform` | `module.registry.azurerm_container_registry.this` | `acrhdshareddev` |
| `platform` | `module.configuration.azurerm_app_configuration.this` | `appcs-hd-shared-dev` |
| `platform` | `module.messaging.azurerm_servicebus_namespace.this` | `sb-hd-shared-dev` |
| `nodes/pulse` | `module.access["acr_pull"].azurerm_role_assignment.this` | Exact existing assignment ID |
| `nodes/pulse` | `module.access["configuration_reader"].azurerm_role_assignment.this` | Exact existing assignment ID |
| `nodes/pulse` | `module.access["vault_reader"].azurerm_role_assignment.this` | Exact existing assignment ID |

Do not import Pulse's app/vault into these roots. Names/principal IDs do not
uniquely identify grants; inventory the actual UUID and scope. Tightening RG
grants to resource scopes is a separate access migration.

`prevent_destroy` only protects blocks still present in configuration. Removing
the block also removes that protection. Review, protected state access, backups
and no-delete plan policy remain necessary. Do not use `state rm`, `state push`,
force-unlock, `-lock=false`, `-replace` or `-target` to bypass adoption failures.

## New-resource sequence — also not executed

After cost/name/CIDR/identity and backend approval: network, shared SQL server,
explicit subnet access, Identity database/vault, then stopped plan/app. Each root
needs its own reviewed plan/apply; success grants no authority for the next root.
Queues wait for consumer/recovery approval. Shared services are not duplicated.

SQL publishing stays disabled: the exact executor and tested all-DDL-writer
maintenance freeze remain unapproved. Database creation is not permission for
DACPAC publishing, contained users or workers. No SQL provider or provisioner is
present. B1 has no slots or multi-instance health failover; explicit retained-image
rollback may interrupt service. Obtain fresh approved pricing before provisioning.

Future deployment automation must separately review main-only provenance,
protected Environment reviewers (including dev), explicit enablement, OIDC scope,
state-key concurrency, confidential saved plans and same-plan apply binding.
This migration supplies no dispatchable apply/import workflow. Merge, access
setup, state adoption and deployment are distinct approvals. Installed Greptile
does not establish enforced or completed review.

The observed Infrastructure ruleset requires `Bicep Lint / Bicep Lint`. A named
compatibility gate retains that exact context and fails unless the full Terraform
suite, ownership tests and secret scan all succeed. It no longer runs Bicep.
No ruleset or branch protection is modified; renaming the context is a separately
coordinated ruleset update. Neither repository currently wires Sonar into these
IaC/Actions workflows; absence of an analysis is not zero-new-issues evidence.
