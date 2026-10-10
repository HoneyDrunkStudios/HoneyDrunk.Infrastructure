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

## Options and recommendation

| Option | Boundary and feasibility | Incremental network fixed cost, 730 hours |
|---|---|---:|
| Existing `cae-hd-dev`, explicit current app IP allowlist | No guaranteed static egress. Can support a consciously accepted temporary dev trial after the real Identity IP list is observed, but changes can break SQL. Not the recommended stable design; no Pulse IP reuse or broad allowlist | $0 new network resources, with an unresolved availability gate |
| **New workload-profile environment using only Consumption, VNet plus classic `Microsoft.Sql` service endpoint** | Recommended economical dev design: SQL accepts the exact ACA subnet, regardless of public egress IP changes. SQL still has a public endpoint for narrowly allowed operator/runner access; Entra/contained-user grants enforce database isolation | About **$25.55** for ACA-managed Standard LB and two Standard public IPv4s; classic service endpoint has no extra charge |
| New VNet workload-profile environment plus **Standard NAT Gateway** and one assigned static IPv4 | Supported bounded public egress for SQL and other internet destinations. Additional resources/cost are unnecessary if only SQL needs this boundary. StandardV2 NAT is not supported by ACA | Conservatively **$62.05**: $25.55 base plus $32.85 NAT plus $3.65 NAT IP; data charges additional |
| New VNet environment plus **SQL private endpoint** | Strongest SQL network isolation if public access is disabled. Requires private DNS, private-connected schema runner and an operator private-access path. Do not confuse SQL PE with an ACA inbound private endpoint | $25.55 base plus **$7.30 SQL PE**, DNS/query/data charges and operator access; not a complete all-in quote |

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
It uses only the Consumption workload profile, without dedicated instances,
planned maintenance or an ACA inbound private endpoint. Continue using
`acrhdshareddev` and `log-hd-shared-dev`.

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

## Operator login and schema runner

For the recommended public-SQL/subnet option, use SSMS or another supported SQL
client from the operator's approved workstation, targeting
`sql-hd-shared-dev.database.windows.net`, database `sqldb-hd-identity-dev`.
Use interactive workforce Entra/MFA authentication, Encrypt=True and
TrustServerCertificate=False. No SQL password. Identify and approve the exact
workforce administrator group/name/object ID and the workstation's actual public
egress /32. An ISP address change requires another reviewed rule update; it must
not silently broaden access. Remove temporary operator exceptions through an
explicit approved change after bootstrap/maintenance. No client IP has been selected.

Prefer a **GitHub-hosted Linux x64 4-core larger runner with its assigned static
IP range**, proposed label `hd-identity-sql-dev`. Existing Team eligibility avoids
an assumed subscription upgrade. It costs **$0.012/minute**, has no idle-runner or
static-IP feature charge, and avoids maintaining a new self-hosted VM. Budget
200 billed minutes/month across plan/revalidation jobs = **$2.40**, or 1,000 minutes
= $12.00; rounded minutes, package downloads and retries count. Included/free
minutes do not cover this runner. Restrict the runner group to Identity and the
reviewed schema workflows where supported; retain main-only dispatch and protected
environments. Review the actual assigned finite range before any SQL rule.
[Runner rates](https://docs.github.com/en/billing/reference/actions-runner-pricing),
[larger-runner capabilities](https://docs.github.com/en/actions/concepts/runners/larger-runners).

Configure `IDENTITY_SQL_RUNNER` to that approved runner and `IDENTITY_SQL_SERVER`
to the shared FQDN only after setup. Planner and publisher continue using separate
tenant-only OIDC identities: no subscription ID/ARM role merely to obtain a SQL
token. Runtime SQL DML, planner read/VIEW DEFINITION and publisher database-scoped
DDL privileges are distinct; no identity receives another application's DB rights.
No automatic hosted-runner-IP discovery/firewall changes are proposed.

For private SQL, GitHub's Azure private-network integration is an alternative to
static public runner IPs, but its Azure network-settings/subnet/permissions need
separate implementation and approval. Operator SSMS then needs a reviewed VPN or
other private-connected workstation; neither exists in the verified inventory.
Do not disable SQL public access and pretend the operator can still log in from
Nov. That alternative's access-path cost must be quoted before selection.

For either option, use the SQL FQDN rather than an IP. Decide and review server
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

Recommended-option illustration: **$25.55 network + $4.90 SQL + $19.71 one active
API replica + $2.40 runner = $52.56/month** before usage-dependent extras. NAT's
conservative version is **$89.06/month** on the same assumptions. Keep the managed
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
3. Approve the exact Entra admin group, runtime/planner/publisher users/grants,
   larger-runner creation/billing/static range, operator /32 and SQL subnet rule.
   New environment join/read rights must target that environment, not Pulse's grant.
4. After separately authorized setup, prove allowed application/runner/operator
   connections and denial from an unapproved source; prove runtime DDL denial,
   mapped-schema readiness, candidate sign-in, image pull, Vault/Graph access and
   telemetry delivery. Verify across revision changes/scale and inspect the full
   firewall/rule set. No live acceptance is claimed here.
5. Keep schema execution disabled. An **all-DDL-writer maintenance freeze** remains
   unapproved; topology selection does not authorize the executor or a schema run.

No resource, administrator, role, firewall, credential, consent, GitHub setting,
merge or deployment was changed while preparing this proposal.
