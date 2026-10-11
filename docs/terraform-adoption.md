# Existing development estate ownership

The founder authorized existing-resource adoption on October 11, 2026. This
supersedes the earlier exclusions of Pulse, Notify, automation and directory
resources. Adoption itself did not authorize new deployment. The founder subsequently
authorized and completed the Identity foundation/runtime release described in
[the migration record](terraform-migration.md). The original imported-estate manifest is
[adoption-manifest.json](../adoption-manifest.json). Import IDs use each pinned
provider's syntax; some differ from ARM IDs.

## State and source boundaries

| Root | Container suffix after `tfstate-` | State key |
| --- | --- | --- |
| bootstrap/state | bootstrap-dev | dev/bootstrap.tfstate |
| platform/resource-groups | resource-groups-dev | dev/resource-groups.tfstate |
| platform | platform-dev | dev/platform.tfstate |
| platform/access | access-dev | dev/access.tfstate |
| platform/monitoring | monitoring-dev | dev/monitoring.tfstate |
| nodes/automation | automation-dev | dev/automation.tfstate |
| nodes/pulse-runtime | pulse-dev | dev/pulse.tfstate |
| nodes/notify | notify-dev | dev/notify.tfstate |
| directory/deployment-access | deployment-access-dev | dev/deployment-access.tfstate |
| directory/customer | customer-directory-dev | dev/customer-directory.tfstate |
| directory/customer-applications | customer-directory-dev | dev/customer-applications.tfstate |
| directory/customer-flow | customer-directory-dev | dev/customer-flow.tfstate |
| platform/app-network (deployed) | app-network-dev | dev/app-network.tfstate |
| platform/sql (deployed) | sql-dev | dev/sql.tfstate |
| platform/sql-access (deployed) | sql-access-dev | dev/sql-access.tfstate |
| nodes/identity (deployed) | identity-dev | dev/identity.tfstate |
| nodes/identity-data (deployed) | identity-data-dev | dev/identity-data.tfstate |
| nodes/identity-vault (deployed) | identity-vault-dev | dev/identity-vault.tfstate |

The original manifest is the preserved import inventory, not a complete list of
subsequently created resources. The six deployed roots above own their configured
resources, provider registrations and scoped grants. Customer-applications also
owns `azuread_application_certificate.identity_runtime_20261011`.
`nodes/identity-messaging` has no deployed resources/state; its reserved backend
is not a deployment authorization.

All deployed roots use the protected `sthdtfstatedev` account. Customer roots share the same
operator access boundary but have separate keys, locks and provider tenant
configuration. ARM directory ownership uses the workforce tenant; customer
applications and flow use the customer tenant. Names, subscriptions, tenants and
legacy tags are intentional development configuration, not production defaults.

The former `nodes/pulse` grant-only root is retired before adoption. Its three
existing grants are owned once, by `platform/access`. No other state was moved or
overwritten. Resource groups are independent of application lifetime. System
identities remain attached to their apps; no replacement service principal is
created. Existing grant UUIDs, scopes, custom role and founder Owner access remain.

## Runtime and provider exceptions

- Identity releases own image, app settings, enabled state and health path.
  Terraform owns its Central US app/plan, SQL infrastructure, per-IP firewall,
  workforce administration and scoped registry/vault grants. SQL schema and
  contained-user permissions, private certificates and secret values are separate
  runtime operations. The East US 2 app network remains preserved and unconnected.
- Pulse releases own image, environment, Key Vault references, revision suffix
  and traffic weights. Terraform owns app infrastructure and its vault. Registry
  identity casing is ignored because Azure returns `system` while AzureRM requires
  `System`; the registry server and other ingress settings remain managed.
- Notify releases own app settings/package and deployment storage credentials.
  Terraform manages the FC1 plan, Flex app, system identity, scale, storage,
  containers, queue, vault and Insights. Source obtains the existing storage key
  and Insights connection string through resource references, never literals.
  Empty imported IP-restriction default representations are preserved separately;
  actual restriction rules remain managed. No shared-key migration occurred.
- App Configuration developer SKU reports zero soft-delete days, outside the
  provider's configurable range. That Standard-only property is ignored. The
  workspace's omitted local-auth field is also preserved instead of applying a
  provider default. These fields are excluded from drift enforcement; changing
  them requires a specific provider/API review, not an unreviewed update.
- The existing CIAM domain exceeds AzAPI's embedded name limit. Local schema
  validation is disabled while its imported validation metadata is ignored, so
  adoption does not PUT the tenant merely to update a provider flag. The directory
  body, tenant link, SKU and location remain managed. Never replace the tenant.
- AzureAD cannot reconstruct imported certificate payload/encoding. Both adopted
  public certificates are retained, with those two write-only fields ignored;
  key ID, validity and application association remain managed. No private key or
  replacement credential is in source. Rotation requires an explicit new plan.
- Microsoft Graph imports a flow ID without its body. The founder separately
  approved copying the existing settings into managed state through same-value
  PATCH operations. Provider and attribute links are separate imported `$ref`
  resources; their matching reference bodies are recorded without remote writes.
  The application-to-flow association is monitored with a failing postcondition
  on every plan, but is not writable through this provider: Graph rejects the
  nested PATCH and exposes no item GET for import. It remains an explicit
  adoption gap requiring a supported association resource, not a fake import.
  An ID-only import is not complete configuration adoption.

No `ignore_changes = all` is used. Inspect each exception before changing its
ownership; do not use ignored fields to conceal unrelated drift. Application
deployments must coordinate with future infrastructure writes to the same app.
This adoption supplies no dispatchable live apply workflow or deployment freeze.

## What remains service-owned or data-owned

Azure-managed revisions, Log Analytics built-in tables, platform-created enterprise
applications, the B2C extension app and built-in user attributes/providers are
service-owned. They are not recreated as hundreds of Terraform resources.
Vault secret values, App Configuration entries, blobs, messages, registry images,
logs and customer users are application data or credential material, not imported
payloads. They stay in place. NuGet rotation is separate operational work.

The disabled `honeyhub-dev` subscription returned SubscriptionNotFound. Do not
claim it is empty, reactivate it, or delete it through this configuration. The customer-tenant inventory found two built-in providers and eleven built-in
attributes, with no custom objects to adopt. Microsoft Graph PowerShell was needed
for these two read inventories because Azure CLI cannot request their scopes.

## Planning, apply and recovery

1. Authenticate to the intended tenant/subscription and initialize the exact
   existing backend. Never initialize an empty local backend for an adopted root.
2. Keep state, plan files, JSON, credentials and command logs on protected local
   storage. Terraform state can contain keys even when source has no secret.
3. Use the exact manifest to prepare imports only for missing mappings. Require
   zero create/update/delete/replacement operations, validate names and IDs and
   review the saved plan. The separately approved flow exception does not relax
   this rule for other resources or later changes.
4. Keep locking enabled and apply only that saved plan. Never use `-target`,
   `-lock=false`, state replacement or a destructive apply to repair adoption.
5. Require a fresh no-change plan and compare live resource IDs, access, app
   identities, revisions/traffic and configuration with the baseline. No-change
   plans do not establish customer sign-in or end-to-end notification delivery.
6. Before corrective state removal, preserve the latest state and review a
   `removed` block with `destroy = false`. Never restore an old snapshot over a
   newer writer. `prevent_destroy` is not protection after removing its block.

Backend recovery was tested with a uniquely named scratch blob: previous-version
download matched SHA256 and a finite lease rejected an unowned overwrite. The
bootstrap state migrated with unchanged resource contents and lineage, followed
by a no-change plan. Current blobs do not expire; earlier versions expire after
90 days and blob/container soft deletion lasts 30 days. This is state recovery
evidence, not a recovery test for SQL, apps or customer identity.
