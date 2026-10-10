# Identity development hosting and SQL connectivity

The user selected Linux B1 App Service on October 9, 2026 (America/New_York). This replaces the earlier
Container Apps networking proposal. Source preparation is authorized; spending,
CIDRs, provisioning, permissions, credentials, consent, merge and deployment are not.

## Verified support and inventory

Microsoft supports Basic-tier regional VNet integration with a same-region,
unused subnet delegated to `Microsoft.Web/serverFarms`. Minimum size is /28;
reserve /26 for upgrade/scaling headroom after overlap review. Integration supports
SQL service endpoints and is outbound connectivity; the API remains public HTTPS.
[App Service networking](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration).

Keep the existing non-root .NET 10 Linux Docker image. App Service supports a
single custom Linux container, system-managed identity ACR pulls, a configured
HTTP port and application settings. The Dockerfile supplies the runtime rather
than depending on built-in runtime rollout. ACR ARM-token acceptance was verified
**enabled** read-only. [Containers and MI](https://learn.microsoft.com/en-us/azure/app-service/configure-custom-container),
[.NET images](https://learn.microsoft.com/en-us/dotnet/core/docker/container-images).

Read-only `honeydrunk-dev` inventory found no customer VNet or SQL logical server.
The existing Notify plan `ASP-rghdnotifydev-898e` is FC1, not a reusable B1 plan.
Existing platform ACR/logs remain reusable. `cae-hd-dev` and healthy Pulse remain
untouched; Identity now has no Container Apps dependency. Subscription:
`82073da5-bd6d-4874-947e-73b791054cbc`; workforce tenant:
`f5654adb-2a4c-4317-9217-09ef32ccdd3a`.

## Prepared resource boundaries

All names below are proposed; no resource, hostname, object ID or address allocation
is claimed to exist. Recheck global Web App/SQL/vault names and regional capacity
before apply. App hostnames must come from Azure's `defaultHostName`, including
any unique hostname suffix, never from name concatenation.

| Resource | Owner / scope |
|---|---|
| `vnet-hd-apps-dev`, `snet-app-service` | `platform/app-network` in existing `rg-hd-platform-dev`, East US 2; explicit CIDRs only |
| `sql-hd-shared-dev`, `app-service-dev` subnet rule | Isolated `platform/sql`; server/admin/public firewall and SQL subnet permission stay platform-owned |
| `sqldb-hd-identity-dev` | Identity-owned Basic database on the existing shared server, in the platform group; no server/admin/firewall writes |
| `asp-hd-identity-dev` | Dedicated Linux B1 plan, one instance, in existing `rg-hd-identity-dev` |
| `app-hd-identity-dev` | Identity Linux Web App with system MI; source name is overridable after collision review |
| `kv-hd-identity-dev` | Dedicated Standard vault; no certificate/secret material created |

Shared tags: `hd:node=honeydrunk-infrastructure`, `hd:env=dev`,
`hd:owner=honeydrunkstudios`, `hd:cost-center=core-infra`, `hd:dr-tier=T1`,
`hd:adr=ADR-0077`. Identity database/plan/app/vault use `honeydrunk-identity`,
`identity`, `T2` for node/cost-center/DR. Existing group tags are unchanged.
No Pocket Quests database, deployment slot, NAT, public IP, load balancer,
private endpoint, private DNS, VM or new Container Apps environment is declared.
Optional lifecycle queues remain disabled and separately reviewed.

## Network and security approval sequence

1. Approve the VNet address space and integration subnet after comparing Azure,
   workstation/VPN/on-premises and planned peering routes. No CIDR is selected.
   `target=platform-app-network` accepts only explicit `networkSetup` with
   `addressPrefix` and `subnetPrefix`. The resolver checks canonical RFC1918 IPv4,
   subnet containment and /28 minimum; it cannot establish live overlap safety.
   Empty parameters write nothing. Only dev has a parameter file/dispatch path.
2. Review the dedicated network leaf's what-if and separately approve apply.
   It owns the complete new VNet/subnet declaration. Before future network updates,
   inspect all existing subnets; never delete an independently added runner subnet
   by replaying an incomplete VNet declaration. Do not replay broad platform IaC.
3. Create the shared SQL server with its approved workforce Entra administrator
   group and explicit operator firewall list. `allowAppServiceSubnet=true` adds
   only the exact App Service SQL VNet rule; it can run independently of server
   setup, after the subnet endpoint exists. `ignoreMissingVnetServiceEndpoint=false`
   prevents bypassing that prerequisite. Omission does not remove old rules.
4. Approve app integration rights: VNet/subnet read and subnet join at the exact
   subnet. Network provisioning/delegation needs subnet write; SQL rule creation
   also needs `joinViaServiceEndpoint/action` on that subnet. These are not Pulse
   environment join permissions. The API runtime identity needs no network ARM role.
5. App Service routes application traffic through integration so public SQL
   service-endpoint destinations use the subnet boundary. Container image pulls
   retain their existing public ACR route; no private ACR or NAT is needed.
   No blanket public SQL allowlist or `0.0.0.0` Azure-services bypass is allowed.
   SQL DNS stays public; subnet rules are server-wide network access, while
   contained users isolate database authorization. Review the whole live rule set.

Sources: [routing](https://learn.microsoft.com/en-us/azure/app-service/configure-vnet-integration-routing),
[SQL VNet rules](https://learn.microsoft.com/en-us/azure/azure-sql/database/vnet-service-endpoint-rule-overview?view=azuresql),
[classic service endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview).
Use the SQL FQDN. Default Azure SQL Redirect may require TCP 1433 plus 11000-11999
through future NSGs; Proxy is a separate server-wide latency/throughput decision.
No NSG, UDR, connection-policy change or unreviewed address rule is applied here.

## Operator schema path and later automation

Initial schema review uses an approved workstation /32, workforce Entra/MFA,
validated TLS (`Encrypt=True;TrustServerCertificate=False`) and an inspection-only
contained planner user/group. The logical-server administrator is for bootstrap.
An ISP IP change needs a separately reviewed rule update; remove temporary access
through an explicit approved change after maintenance.

Pin source and repository tool versions, build the Azure SQL DACPAC, then use
Identity's `scripts/Review-DevDatabase.ps1 -Action Plan` with the exact shared SQL
FQDN, database, source revision and fresh review directory. Azure CLI must already
hold the approved workforce session. Preserve `deploy.sql`, `deploy-report.xml`,
`manifest.json` and tool/build evidence; tokens stay in memory and out of logs.

**Stop before execution.** The all-DDL-writer maintenance freeze remains unapproved.
The exact-script executor has not been implemented/reviewed; `Publish` still always
refuses execution after drift verification. Manual SSMS execution or SqlPackage
Publish is not a bypass. Operator application of the reviewed schema requires
separate live approval after those gates, using database-scoped publisher access.

GitHub Team cannot use assigned static-IP larger runners (Enterprise Cloud is
required); no plan upgrade or self-hosted VM is proposed. Later Team Azure private
networking supports East US 2 with a separate subnet delegated to
`GitHub.Network/networkSettings`, its own SQL endpoint/rule, network-settings and
service permissions, runner restrictions and approved egress. It cannot share the
App Service delegated subnet. This is a future option, not implemented or budgeted.
[Static-IP restriction](https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/manage-larger-runners#creating-static-ip-addresses-for-larger-runners),
[Team private networking](https://docs.github.com/en/organizations/managing-organization-settings/about-azure-private-networking-for-github-hosted-runners-in-your-organization).

## Reverified cost baseline, 2026-10-10

USD PAYG East US 2, one instance, 730 hours, no discounts or free allowances:

| Meter | Verified rate | Baseline |
|---|---:|---:|
| Linux App Service B1: 1 core, 1.75 GB RAM, 10 GB storage | $0.017/hour | $12.41/month |
| SQL Database Single Basic, SKU B / meter B DTU, 5 DTU / 2 GiB | $0.161/day | About $4.90/month |
| Classic SQL service endpoint | No extra endpoint charge | $0 |

**$17.31/month is the plan-plus-database baseline, not the whole bill or a ceiling.**
The App Service rate is from the official page's embedded East US 2 pricing data;
the SQL rate is from the Retail Prices API, meter `cae64797-9ecf-4906-b517-6238c80c045f`.
[Linux pricing](https://azure.microsoft.com/en-us/pricing/details/app-service/linux/),
[SQL pricing](https://azure.microsoft.com/en-us/pricing/details/azure-sql-database/single/),
[Retail API](https://prices.azure.com/api/retail/prices?$filter=serviceName%20eq%20'SQL%20Database'%20and%20armRegionName%20eq%20'eastus2'%20and%20skuName%20eq%20'B').

Excluded: shared ACR storage/build traffic, Vault/certificate operations, telemetry
and log ingestion/retention, bandwidth, Service Bus, extra/LTR backup storage,
Defender/auditing, future runners, operator time and taxes/currency. Stopping the
site does not stop the dedicated plan's charges. A second B1 instance roughly
doubles the plan component. Basic SQL remains provisioned; no auto-pause is assumed.
Approve a refreshed quote and budget before any live action.

## Health and release limitations

B1 has no deployment slots. CD changes the serving site's immutable image digest
and waits for three consecutive matching `X-Identity-Release` responses from both
`/health/live` and SQL/schema readiness `/health`. Warm-up requires HTTP 200 from
`/health`; Always On is enabled. This prevents a still-serving old image's healthy
response being mistaken for the new release. Configuration changes, deployment and
rollback can interrupt service; no isolated candidate or zero-downtime promise.
[Slots](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots),
[warm-up settings](https://learn.microsoft.com/en-us/azure/app-service/reference-app-settings).

Health Check monitors the site every minute. With one instance it does not remove
an unhealthy instance from traffic; replacement can take an hour. Health success
is not Graph/sign-in, DML, telemetry or recovery acceptance.
[Health limitations](https://learn.microsoft.com/en-us/azure/app-service/monitor-instances-health-check).
Rollback explicitly redeploys a retained image/release pair and rechecks health;
it cannot restore SQL, settings, certificates or consent. Keep reviewed release
artifacts and ACR images, coordinate IaC/CD, and perform live acceptance only after
approval. No live setup, test, merge or deployment occurred in this task.

