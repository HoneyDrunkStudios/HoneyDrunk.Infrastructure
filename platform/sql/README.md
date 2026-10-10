# Shared development SQL

The user selected the shared-server/Basic design for implementation on 2026-10-10.
This is source preparation, not permission to create resources, incur charges,
configure administrators/firewalls/roles, deploy schema, merge or deploy apps.

## Ownership and selected resources

`platform/sql` is an isolated resource-group deployment into the **existing**
`rg-hd-platform-dev`, **East US 2**. It is deliberately not imported into
`platform/main.bicep`: SQL work must not replay the shared ACA/ACR/Pulse platform.

| Resource | Owner and configuration |
|---|---|
| `sql-hd-shared-dev` | Platform-owned logical server; Entra-only group administrator, TLS 1.2 minimum, public endpoint with an empty firewall unless explicit rules are approved |
| `sqldb-hd-identity-dev` | Identity-owned child database on that server, declared in `nodes/identity`; Basic 5 DTU / 2 GiB, local backup redundancy, seven-day PITR |
| Pocket Quests database | Not declared or created; separate future decision |

Server and database ARM resources share the platform resource group because the
database is a server child. Database deployment does not PUT the server, its
administrator, firewall, or any other database. SQL permissions remain database
scoped and are not in Bicep or the DACPAC.

| Tag | Shared server | Identity database |
|---|---|---|
| `hd:node` | `honeydrunk-infrastructure` | `honeydrunk-identity` |
| `hd:env` | `dev` | `dev` |
| `hd:owner` | `honeydrunkstudios` | `honeydrunkstudios` |
| `hd:cost-center` | `core-infra` | `identity` |
| `hd:dr-tier` | `T1` | `T2` |
| `hd:adr` | `ADR-0077` | `ADR-0077` |

Server tags match the read-only observed platform resources; database tags match
Identity's parameter file. Existing resource-group tags are not changed.

## Explicit dispatcher contract

After separate live approval, select `target=platform-sql`, `env=dev`, and leave
`node`, bootstrap and app-maintenance inputs empty/false. `sql-parameters` accepts
`serverSetup` as `{ "serverSetup": { "administratorLogin": "<approved group name>",
"administratorObjectId": "<verified canonical group UUID>", "firewallRules": [] } }`.
It also accepts `allowAppServiceSubnet: true` to add the exact App Service subnet rule after the service endpoint exists, independently of server setup. No database or app fields are accepted. These are nonsecret references. No administrator is checked in or guessed.

The checked-in parameters omit `serverSetup`; this compiles to **no SQL writes**.
The output name alone is not existence evidence. The dispatcher rejects other
environments, node/app inputs, unknown fields, invalid/zero/noncanonical IDs,
non-string IPv4 addresses, reversed ranges, duplicate/invalid rule names and
the `0.0.0.0` Azure-services bypass before Azure login. Direct Bicep invocations
must separately follow these review constraints; the dispatcher is not Azure RBAC.

Review a what-if restricted to this SQL leaf, then approve apply separately.
Server creation requires an approved workforce Entra administrator group and
name recheck. `sql-hd-shared-dev` was available on 2026-10-10, not reserved.
For later server maintenance, resubmit the verified existing administrator;
review and rehearse that PUT. Incremental ARM deployments do not remove omitted
firewall rules: review the entire live set and explicitly approve obsolete-rule
removal. No automatic destructive cleanup is implemented.

Once the server exists, Identity's separate target uses `provisionDatabase=true`
to deploy only its database module into `rg-hd-platform-dev`. The module accepts
an existing server name and database tags, no administrator or firewall inputs.
For first node creation it may accompany the reviewed placeholder/vault bootstrap;
otherwise Identity outputs require the existing app. Do not mix database creation
and `appUpdate`. Default Identity runs leave database/server/app state untouched.

The existing Infrastructure principal's platform access is not authorization to
run this deployment. A scoped database-only publisher would need server read,
database/retention write on this server and ARM deployment rights at the target
group; these are separate from SQL data-plane runtime/planner/publisher permissions.
No new Contributor, User Access Administrator, SQL user or grant is created here.

## Connectivity and SQL execution holds

Read [the costed connectivity proposal](connectivity.md) before approving any
resources. The selected development design uses App Service regional VNet integration
and the exact SQL subnet rule. Source is prepared, but no network has been
provisioned. Creating a SQL server alone is not proof the application can connect.

Initial schema review is proposed from an approved workstation /32 using workforce
Entra/MFA and inspection-only SQL access. Later automation can use GitHub Team's
Azure private networking on a separate runner subnet after setup/permission review;
assigned static-IP larger runners require Enterprise Cloud and are not proposed.
Identity's SQL Script/DeployReport workflow and tenant-only OIDC identities remain
prepared for that later option. **SQL execution stays disabled** pending the explicit
all-DDL-writer maintenance-freeze decision and a supported executor with real database tests.
Shared topology approval does not accept a freeze, grant access, or enable Publish.

## Validation

Use the pinned Bicep/CLI toolchain in [Pulse's offline instructions](../../nodes/pulse/README.md#offline-verification).
The tests compile modules and dev parameters, inspect deployment scopes/write
boundaries, assert exact tags/SKU/backups, reject unsafe input and transport a
group name with spaces plus firewall settings through the real Azure CLI parser.
No login, what-if, resource creation or SQL connection is performed by these tests.

