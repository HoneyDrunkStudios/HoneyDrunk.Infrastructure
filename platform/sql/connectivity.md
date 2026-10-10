# Identity development SQL connectivity proposal

Evidence date: 2026-10-10. The shared SQL server/Basic database source design is
approved for implementation. **Network selection, spending, provisioning,
administrator/firewall/role changes and SQL execution remain unapproved.**

## Current evidence

Read-only inventory of `honeydrunk-dev` (`82073da5-bd6d-4874-947e-73b791054cbc`,
workforce tenant `f5654adb-2a4c-4317-9217-09ef32ccdd3a`) finds no SQL logical server,
customer VNet or VM. `rg-hd-platform-dev` and `rg-hd-identity-dev` exist in East US 2.
The former has legacy RG tags `env=dev,purpose=platform-shared`; the latter has no
RG tags. Do not retag them as part of SQL work.

Raw ARM API 2025-07-01 reports `cae-hd-dev` with public access Enabled and null
`vnetConfiguration`, `workloadProfiles` and `infrastructureResourceGroup`. Pulse
uses this healthy environment. Its traffic, networking and permissions are not
targets. Microsoft documents that network type cannot be changed after environment
creation, legacy Consumption-only environments do not support NAT/custom egress,
and default outbound addresses can change. An observed app IP list is not a stable
contract. [ACA networking](https://learn.microsoft.com/en-us/azure/container-apps/networking).

The existing shared ACR and logs can still be reused with either candidate. SQL
name availability returned true for `sql-hd-shared-dev`; it is not reserved.
The org read API reports GitHub **Team**. Both the organization's hosted-larger-runner
list and Identity's self-hosted runner list are empty. No runner was created.
Team supports larger runners, but **assigned static public IP ranges require
GitHub Enterprise Cloud**. The earlier Team/static-IP recommendation was incorrect
and is withdrawn; no Enterprise upgrade is proposed.
[Static-IP eligibility](https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/manage-larger-runners#creating-static-ip-addresses-for-larger-runners).

## Options and recommendation

| Option | Boundary and feasibility | Incremental network fixed cost, 730 hours |
|---|---|---:|
| Existing `cae-hd-dev`, explicit current app IP allowlist | No guaranteed static egress. Can support a consciously accepted temporary dev trial after the real Identity IP list is observed, but changes can break SQL. Not the recommended stable design; no Pulse IP reuse or broad allowlist | $0 new network resources, with an unresolved availability gate |
| **New workload profiles v2 environment with the Consumption profile, VNet plus classic `Microsoft.Sql` service endpoint** | Recommended economical dev design: SQL accepts the exact ACA subnet, regardless of public egress IP changes. SQL retains its public endpoint for the approved operator /32; Entra/contained-user grants enforce database isolation | About **$25.55** for ACA-managed Standard LB and two Standard public IPv4s; classic service endpoint has no extra charge |
| New VNet workload profiles v2 environment with the Consumption profile plus **Standard NAT Gateway** and one assigned static IPv4 | Supported bounded public egress for SQL and other internet destinations. Additional resources/cost are unnecessary if only SQL needs this boundary. StandardV2 NAT is not supported by ACA | Conservatively **$62.05**: $25.55 base plus $32.85 NAT plus $3.65 NAT IP; data charges additional |
| New VNet workload profiles v2 environment with the Consumption profile plus **SQL private endpoint** | Strongest SQL network isolation if public access is disabled. Requires private DNS, private-connected schema runner and an operator private-access path. Do not confuse SQL PE with an ACA inbound private endpoint | $25.55 base plus **$7.30 SQL PE**, DNS/query/data charges and operator access; not a complete all-in quote |

The recommended endpoint is the generally available **classic** subnet service
endpoint, not the newer billed Standard service endpoint/Network Security Perimeter
feature. Microsoft documents classic endpoints on managed-service subnets, their
SQL support, and no added endpoint charge. This is a proposal using those supported
building blocks; the exact ACA route/firewall behavior still needs an approved
what-if and live acceptance. No custom proxy, dynamic firewall updater or tunnel is
proposed. [Classic service endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview).

SQL VNet rules are server-wide and same-region. A subnet permission allows network
reachability to the shared server, not authorization to another database. Retain
separate database users and exact grants. Keep Allow Azure services disabled.
[SQL VNet rules](https://learn.microsoft.com/en-us/azure/azure-sql/database/vnet-service-endpoint-rule-overview?view=azuresql).

## Proposed network names and ownership (not implemented)

For the recommended option, propose platform-owned `vnet-hd-apps-dev` and
`cae-hd-apps-dev`, East US 2, in existing `rg-hd-platform-dev`. Use a dedicated
`snet-aca` delegated to `Microsoft.App/environments`; reserve a /26 for headroom
(minimum /27). Exact address prefixes require an overlap check with the operator's
networks/future peering before approval. No IP range is silently selected. The
environment remains externally accessible for the customer-facing HTTPS API.
Use a **workload profiles v2 environment with the Consumption profile**, not the
legacy Consumption-only v1 environment type. No Dedicated profile, dedicated
instances, planned maintenance or ACA inbound private endpoint is proposed.
Continue using `acrhdshareddev` and `log-hd-shared-dev`.
[Environment types](https://learn.microsoft.com/en-us/azure/container-apps/environment).

The VNet, environment and optional NAT/IP use the server's verified platform tags:
`hd:node=honeydrunk-infrastructure`, `hd:env=dev`, `hd:owner=honeydrunkstudios`,
`hd:cost-center=core-infra`, `hd:dr-tier=T1`, `hd:adr=ADR-0077`. Identity app/vault
remain in `rg-hd-identity-dev`; the database is a child of the platform SQL server,
tagged `hd:node=honeydrunk-identity`, `hd:cost-center=identity`, `hd:dr-tier=T2`,
with the same other three values. No Pocket Quests database is created.

After network selection, implement a separate narrow network/environment leaf
and update Identity's environment reference before first bootstrap. **Current
Identity Bicep still references `cae-hd-dev`; this PR does not provision the proposed
new network or claim connectivity is solved.** Do not mutate the existing
environment or replay the whole platform. The managed infrastructure RG/LB/IPs
are ACA-owned; leave their configuration to the service. Costs/tags are documented
in [ACA VNet configuration](https://learn.microsoft.com/en-us/azure/container-apps/custom-virtual-networks).

## Initial operator-run schema procedure

For the recommended public-SQL/subnet option, use SSMS or another supported SQL
client from the operator's approved workstation, targeting
`sql-hd-shared-dev.database.windows.net`, database `sqldb-hd-identity-dev`.
Use interactive workforce Entra/MFA authentication, Encrypt=True and
TrustServerCertificate=False. No SQL password. Identify and approve the exact
workforce administrator group/name/object ID and the workstation's actual public
egress /32. An ISP address change requires another reviewed rule update; it must
not silently broaden access. Remove temporary operator exceptions through an
explicit approved change after bootstrap/maintenance. No client IP has been selected.

Recommend the existing workstation, subject to access approval, for initial schema review and, only
after the execution gates below are satisfied, operator-run application of the
reviewed schema. This requires no new VM or paid runner. This is a proposed
procedure, not authorization to connect or execute now:

1. Pin the reviewed source revision and repository tool versions; build the Azure
   SQL DACPAC. After access approval, authenticate interactively to the workforce
   tenant with MFA. Use an approved contained planner user/group with CONNECT,
   VIEW DEFINITION and required table reads, without DDL privileges.
2. Run Identity's `scripts/Review-DevDatabase.ps1` with `Action=Plan`, the exact
   shared FQDN/database, DACPAC, source revision and a fresh review directory.
   Azure CLI must already hold the approved operator's workforce session; the
   script acquires a SQL token in memory. Do not print tokens or command lines.
   Preserve and review `deploy.sql`, `deploy-report.xml`, `manifest.json` and the
   build/tool evidence together, including postdeployment SQL and target hashes.
3. **Stop before execution.** Approve the all-DDL-writer maintenance freeze and
   separately implement, test and review the supported exact-script executor.
   Revalidate both generated SQL and report, reject drift, and protect target
   state through completion. The current `Publish` action always refuses execution;
   pasting SQL into SSMS or invoking SqlPackage Publish is not a workaround.
4. Only with those gates and explicit live approval satisfied, use an approved
   database-scoped operator publisher identity/group for the exact reviewed
   script. Record the outcome, prove runtime DDL denial and schema readiness,
   then end the freeze and remove temporary access through approved changes.

The logical-server administrator group is for bootstrap, not the routine planner.
Exact operator planner/publisher principals and grants still require review;
MFA does not imply SQL authorization. Runtime DML, planner inspection and publisher
DDL remain separate. No automatic firewall updates or broadly allowed GitHub IP
ranges are proposed.

## Later automated schema option on GitHub Team

GitHub Team supports **organization-level Azure private networking for larger
runners**, including **East US 2**. It uses dynamic addresses inside the selected
subnet and does not support the assigned-static-public-IP option. It can therefore
reach public Azure SQL through a classic SQL service endpoint and exact subnet
rule; a SQL private endpoint is not a prerequisite. This combination is a proposal
requiring route/authentication acceptance, not an existing configured path.
[Team eligibility and supported regions](https://docs.github.com/en/organizations/managing-organization-settings/about-azure-private-networking-for-github-hosted-runners-in-your-organization).

Use a separate proposed `snet-github-runners`, never ACA's delegated `snet-aca`.
Review a nonoverlapping CIDR sized for concurrency, delegation to
`GitHub.Network/networkSettings`, the provider registration/network-settings
resource, required Azure service permissions, and GitHub organization network
configuration/runner-group access. Add a classic `Microsoft.Sql` endpoint and a
second exact SQL subnet rule for this runner subnet. Explicitly block inbound
runner connections and review outbound GitHub/package/SQL access. GitHub's current
setup guidance recommends maintained domain-based egress requirements; do not copy
the retired hard-coded IP template. Internet egress design and any added cost must
be settled separately; the ACA subnet's managed egress is not inherited by runners.
[Setup prerequisites and permissions](https://docs.github.com/en/organizations/managing-organization-settings/configuring-private-networking-for-github-hosted-runners-in-your-organization).

A Linux x64 4-core larger runner costs **$0.012/minute**: 200 billed minutes =
**$2.40**, 1,000 = $12.00. Included minutes do not apply. This is incremental runner
compute only, not a quote for the complete private-network setup or initial path.
No Enterprise upgrade or self-hosted VM is proposed.
[Runner rates](https://docs.github.com/en/billing/reference/actions-runner-pricing).

After separate approval and setup, restrict the runner group to Identity and
reviewed schema workflows where supported, retain main-only dispatch/protected
environments, and configure `IDENTITY_SQL_RUNNER` plus `IDENTITY_SQL_SERVER`.
Separate planner/publisher tenant-only OIDC identities need no ARM role merely
to obtain a SQL token; network setup permissions belong to separate administrators.
Automation does not remove the all-DDL-writer freeze or source-level execution hold.

If SQL public access is instead disabled, operator SSMS also needs an approved VPN
or other private-connected workstation; neither exists in verified inventory.
Quote that access path before choosing fully private SQL.

For every option, use the SQL FQDN rather than an IP. Decide and review server
connection policy: Default redirects Azure clients, requiring outbound TCP 1433
and 11000-11999 to the regional SQL service tag; Proxy uses 1433 with a throughput/
latency trade-off. The current module does not alter that server-wide policy.
[SQL connectivity architecture](https://learn.microsoft.com/en-us/azure/azure-sql/database/connectivity-architecture?view=azuresql).

## Cost evidence and exclusions

USD PAYG, East US 2, 730 hours/month; no discounts or free allowance assumed.
The Retail Prices API throttled the new network queries. Instead, the official
pricing pages' embedded `data-amount.regional.us-east-2` values were read on
2026-10-10, not inferred from their rendered `$-` placeholders:

| Meter | Verified rate | Monthly illustration |
|---|---:|---:|
| Standard LB, first five rules | $0.025/hour; $0.005/GB processed | $18.25 fixed |
| Standard regional static IPv4 | $0.005/hour each | Two managed ACA IPs = $7.30 |
| Standard NAT Gateway | $0.045/hour and $0.045/GB processed | $32.85 fixed, plus separate IP/data |
| SQL private endpoint | $0.01/hour; first-PB data tiers $0.01/GB each direction | $7.30 fixed, DNS/access additional |
| ACA active CPU / memory | $0.000024/vCPU-second; $0.000003/GiB-second | 0.25 vCPU / 0.5 GiB continuously active = $19.71 per replica |
| ACA idle CPU / memory | $0.000003/vCPU-second and /GiB-second | Same allocation continuously eligible for idle = $5.91; do not assume this with SQL probes/maintenance |
| External ACA HTTP requests | $0.40/million | Usage-dependent; platform health probes are not billable requests |
| Identity Basic SQL | Parent pricing worker verified $0.161/day | $4.90; 5 DTU / 2 GiB, seven-day PITR |

Sources: [LB](https://azure.microsoft.com/en-us/pricing/details/load-balancer/),
[IPv4](https://azure.microsoft.com/en-us/pricing/details/ip-addresses/),
[NAT](https://azure.microsoft.com/en-us/pricing/details/azure-nat-gateway/),
[Private Link](https://azure.microsoft.com/en-us/pricing/details/private-link/),
[ACA](https://azure.microsoft.com/en-us/pricing/details/container-apps/),
[ACA billing conditions](https://learn.microsoft.com/en-us/azure/container-apps/billing),
[SQL rate query](https://prices.azure.com/api/retail/prices?%24filter=serviceName%20eq%20%27SQL%20Database%27%20and%20armRegionName%20eq%20%27eastus2%27%20and%20priceType%20eq%20%27Consumption%27&currencyCode=%27USD%27).

Initial operator-run option: **$25.55 network + $4.90 SQL + $19.71 one active
API replica = $50.16/month Azure subtotal**, before usage-dependent extras and
operator time. No paid runner is included. NAT's conservative version is
**$86.66/month** on the same operator-run assumptions. The earlier $52.56/$89.06
totals assumed an ineligible Team/static-IP runner and are withdrawn. Later Team
private-network automation adds billed runner minutes and any separately quoted
network setup/egress costs; it is not included in the initial subtotal. Keep the managed
egress IP in that budget until the actual provider resource/billing inventory
proves any replacement; do not count an unverified saving. Recheck live quotes
and approve a budget before creation. These are subtotals, not spending ceilings.

Excluded: taxes/currency, logs/metrics ingestion and retention, Key Vault/certificate
operations, ACR storage/build traffic, Service Bus usage, paid Defender/auditing,
extra/LTR backups, data processing/egress, DNS, VPN/private operator access and
request charges. A second replica or overlapping live/candidate revisions adds
compute; each continuously active replica at this size adds about $19.71/month.
No dedicated-plan management fee is budgeted: do not enable billed dedicated or
environment private-endpoint/maintenance features without revising the estimate.

## Decisions and acceptance still required

1. Select the classic-service-endpoint VNet design, NAT variant, private endpoint
   variant, or explicitly accept temporary unstable IP allowlisting. No network
   option is selected by approval of the shared SQL topology.
2. Approve names/address space, exact current regional quote and spending budget;
   then review the missing network leaf/environment-reference changes before apply.
3. Approve the exact Entra admin group, runtime and operator planner/publisher
   users/grants, operator /32 and ACA SQL subnet rule. New environment join/read
   rights must target that environment, not Pulse's grant. Later automation needs
   separate runner-subnet/network-settings/service-permission, GitHub runner-group,
   OIDC/grant and billing approval; Team has no assigned-static-IP runner option.
4. After separately authorized setup, prove allowed application/operator connections
   (and runner connections only when that option is selected) and denial from an
   unapproved source; prove runtime DDL denial,
   mapped-schema readiness, candidate sign-in, image pull, Vault/Graph access and
   telemetry delivery. Verify across revision changes/scale and inspect the full
   firewall/rule set. No live acceptance is claimed here.
5. Keep schema execution disabled. An **all-DDL-writer maintenance freeze** remains
   unapproved; topology selection does not authorize the executor or a schema run.

No resource, administrator, role, firewall, credential, consent, GitHub setting,
merge or deployment was changed while preparing this proposal.
