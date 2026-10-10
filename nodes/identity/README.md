# Identity development App Service leaf

The selected source design is Linux B1 App Service, regional VNet integration and
shared SQL with an isolated Identity Basic database. Read the [network, cost and
approval plan](../../platform/sql/connectivity.md). No live changes are authorized.

## Ownership and initial sequence

`platform/app-network` owns the dedicated integration VNet/subnet; `platform/sql`
owns the logical server, Entra administrator, public firewall and SQL subnet rule.
Identity owns its database only, plus the dedicated plan, Web App and vault.
Database deployment cannot write server/admin/network configuration. No role
assignments or credentials are created by any of these leaves. Pulse is untouched.

1. Approve names, East US 2 capacity, exact nonoverlapping CIDRs, costs and scoped
   permissions. Network prefixes have no defaults. Review/apply the isolated
   network and SQL targets only after separate live approval.
2. After the SQL server and integration subnet exist, review Identity with
   `bootstrap=true`, `provisionDatabase=true`, `provisionVault=true` for first
   creation. Bootstrap creates one dedicated Linux B1 plan and a **disabled**
   public-image placeholder Web App with system MI. It is not a serving Identity
   API. Never bootstrap over a live app; inspect what-if for replacement.
3. Approve runtime AcrPull, dedicated-vault secret reads and exact SQL table DML,
   and separate operator planner/publisher grants. The app reads the customer-app
   certificate from Vault; the source contains no secret material or guessed IDs.
4. Generate/review the Azure SQL Script, DeployReport and manifest. **Execution is
   disabled** pending the all-DDL-writer freeze and reviewed/tested executor.
5. After schema/credential/configuration gates and separate live approval, build a
   reviewed image with its unique `RELEASE_ID`, push it through an approved path,
   and supply complete `appUpdate`. This enables the Web App, changes its image and
   all declared app settings, and may interrupt service. Coordinate with CD.
6. Default later IaC runs reference the existing site without writing its image,
   settings or plan. CD updates the single serving site directly; B1 has no slots.
   Rollback redeploys the retained digest/release ID, never SQL or app settings.

## Parameters and names

Only `parameters.dev.bicepparam` and dev dispatch are implemented. The leaf is dev-only. Reusable plan sizing parameters permit a later reviewed
implementation;
there is no production deployment, topology, sizing or readiness claim.

| Input | Default / contract |
|---|---|
| `bootstrap` | false; first creation only, disabled placeholder and dedicated plan |
| `provisionDatabase` | false; only `sqldb-hd-identity-dev` on existing `sql-hd-shared-dev` in `rg-hd-platform-dev` |
| `provisionVault` | false; dedicated Standard vault, no certificate value |
| `appUpdate` | null; complete nonsecret runtime configuration for explicit initialization/maintenance |
| `provisionLifecycleQueues` | false; optional queues only, no delivery activation/grants |
| `appName` | proposed `app-hd-identity-dev`; verify global availability before provisioning |
| `planSkuName`, `planSkuTier`, `planCapacity` | B1, Basic, 1; sizing is used at bootstrap, not an implicit later plan update |

`appUpdate` fields: `image` (exact `acrhdshareddev.azurecr.io/honeydrunk-identity-api@sha256:<64 hex>`),
`authority`, `issuer`, `audience`, `mobileClientId`, `apiScope`, `graphTenantId`,
`graphClientId`, `graphCertificateSecretName` (versionless secret name only),
`allowedOrigins` (exact HTTPS origins), `otlpEndpoint`. No ACA revision/traffic field.
The API sets Production environment, port 8080, SQL managed-identity authentication,
explicit customer certificate credentials and a real external collector endpoint.
Do not override the image-baked `Identity__ReleaseId` in App Service settings.

The plan/app/vault are proposed in `rg-hd-identity-dev`. Network and SQL stay in
`rg-hd-platform-dev`. No node write touches the shared Container Apps environment.
Default outputs require an existing app and return Azure's actual hostname and MI
principal ID; outputs do not manufacture live values for nonexistent resources.

Health Check and warm-up use `/health`; `/health/live` only proves process liveness.
The image release header must match during CD validation. Single-instance B1 does
not provide health-based failover. HTTPS and TLS 1.2 minimum are set; FTP and SCM
basic publishing credentials are disabled in source, with OIDC used by CD.

Basic sign-in needs no Service Bus. Optional `identity-lifecycle-acks` and
`pocketquests-lifecycle` queues remain separate from consumer/ack, Graph deletion,
dead-letter and erasure-safe recovery acceptance. Do not claim production readiness.

The reverified B1 + SQL Basic baseline is **$17.31/month**, excluding shared service
usage, logs, Vault, bandwidth, backups, taxes and other extras. See the full cost
plan before approval. No new network CIDR or live access is selected by this PR.

## Offline validation

Use pinned Bicep 0.48.1 and Azure CLI 2.91.0 per [Pulse's tooling setup](../pulse/README.md#offline-verification),
then `python3 -m unittest discover -s tests -v`. Tests compile real templates,
assert ownership/default no-writes, Linux B1/MI/integration/health configuration,
reject unsafe network and app inputs, and transport overrides through the real CLI.
Pulse's existing ownership regressions remain intact. No Azure login or deployment
is performed. The pre-existing Key Vault diagnostic-settings API warning remains.

