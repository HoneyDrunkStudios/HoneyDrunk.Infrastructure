# Identity development leaf

Preparation only: no resource, credential, role, consent or deployment is authorized by this source change. Coordinate with the Identity application's [deployment review](https://github.com/HoneyDrunkStudios/HoneyDrunk.Identity/blob/feat/dev-deployment-readiness/docs/development-deployment.md) for the 2026-10-09 inventory, tenant evidence, cost/access approvals, SQL review/publish procedure and acceptance gates.

## Ownership and stages

Reuse `cae-hd-dev`, `acrhdshareddev`, `log-hd-shared-dev` and (only for a later lifecycle milestone) `sb-hd-shared-dev` in `rg-hd-platform-dev`. The Identity app, SQL logical server/database and Key Vault are separate. No Pulse app, revision, traffic or grant is changed. This leaf creates **no role assignments**.

Default `parameters.dev.bicepparam` references the existing app and performs no app/SQL/vault/queue writes. It cannot bootstrap a missing app; initial deployment needs explicit reviewed inputs. Application CD owns image, revisions and traffic after initialization, preserving Infrastructure #12 / Actions #217's ownership rule.

The existing deploy dispatcher accepts `target=node`, `node=identity`, `env=dev` and a nonsecret `identity-parameters` JSON object. The resolver rejects unrelated nodes, unexpected fields and SQL's Azure-services bypass before Azure login. It encodes spaces within JSON strings for the shared workflow's whitespace-delimited override transport; the CLI contract test verifies the actual Bicep override result. Never pass secret values in this input.

1. **Approve prerequisites.** Resolve cost/SKU, name availability, workforce SQL admin group, stable egress and customer Graph app/certificate metadata. Approve the dedicated workload identities/grants and protected environments described by the application runbook. Existing Infrastructure rights cover platform/Pulse, not Identity. No new access-admin role is needed by this leaf.
2. **First resource bootstrap.** Only for a new app, use `bootstrap=true`, plus reviewed `databaseSetup` and `provisionVault=true`. Review what-if first. The public pinned placeholder starts without private registry credentials or secrets and creates the system MI; its named revision stays at 100%. An empty SQL firewall permits no public client access. The placeholder is not a working Identity service.
3. **Approved access setup.** Grant the runtime MI AcrPull, dedicated-vault secret read. Separately create the SQL runtime contained user and the planning/publishing users; no runtime DDL. Verify the new app's actual outbound addresses before approving narrow SQL rules and stable runner egress. The shared environment has no VNet, so private SQL access needs a separately reviewed network design. Do not copy Pulse's egress or use `0.0.0.0`.
4. **Reviewed schema and certificate.** Use Identity's manual Script/DeployReport/Publish workflow. Inspect or approve transfer/replacement of the customer application's certificate through Key Vault. Infrastructure does not create credentials, consent or SQL users.
5. **App initialization/configuration maintenance.** Pass a complete `appUpdate` with a reviewed **ACR digest** and the full currently known-good named Identity revision. Do not combine it with bootstrap, SQL creation or vault creation. It replaces the app template/configuration intentionally while retaining 100% traffic on that existing revision. New revision validation/promotion remains separate. Freeze CD while this reviewed maintenance runs.
6. **Steady state/CD.** Omit `appUpdate` and resource-setup inputs. Identity CD creates a healthy candidate at zero traffic. After customer sign-in acceptance, explicitly approve promotion of that exact revision. Rollback pins the previously recorded healthy revision; it never rolls SQL data back. Keep previous good revisions active until acceptance.

## Nonsecret parameter contract

| Parameter | Default | Reviewed input |
|---|---|---|
| `databaseSetup` | null | `administratorLogin` (workforce group display name), `administratorObjectId` (group object ID), `firewallRules` array of `{name,startIpAddress,endIpAddress}`. SQL Basic 5 DTU / 2 GiB, Entra-only auth, TLS 1.2, local backup redundancy, seven-day PITR |
| `provisionVault` | false | Explicit permission to create dedicated Standard Key Vault through the existing module; no secret material |
| `bootstrap` | false | Dispatcher input; public pinned placeholder for first creation only |
| `appUpdate` | null | All fields below, supplied together from reviewed evidence |
| `provisionLifecycleQueues` | false | Two queues only; no topic, consumer, namespace configuration, permission or API activation |

`appUpdate` fields: `image` = `acrhdshareddev.azurecr.io/honeydrunk-identity-api@sha256:<64 hex>`, `trafficRevision` = actual `ca-hd-identity-dev--<suffix>`, `authority`, `issuer`, `audience`, `mobileClientId`, `apiScope`, `graphTenantId`, `graphClientId`, `graphCertificateSecretName`, `allowedOrigins` (exact HTTPS origins), `otlpEndpoint` (verified reachable collector). The certificate field is a **versionless secret name**, never a private key/value. Customer Graph tenant is distinct from the Azure workforce tenant. App IDs/collector URL remain unresolved; none are invented in the checked-in parameter file.

The runtime sets `ASPNETCORE_ENVIRONMENT=Production` even on dev infrastructure to avoid development-only credential/localhost behavior. It uses system-MI SQL authentication, the shared Vault bootstrap and the explicit customer certificate credential. API sizing is 0.25 vCPU / 0.5 GiB, min 1 / max 2. Separate live and schema-readiness probes protect startup versus dependency failures. One minimum replica supports retention work; its consumption and overlapping revisions must be included in cost approval.

The SQL module is a dev starting size, not a production sizing policy. Parameter omission is not resource deletion: ARM incremental deployment does not remove old SQL firewall rules or disable previous resources. Inspect and separately approve cleanup; there is no automatic destructive reconciliation. A SQL or vault-only maintenance run expects an existing app because outputs report its identity/FQDN. SQL/vault/queue bootstrap can accompany first app bootstrap.

## Lifecycle scope and acceptance

Basic sign-in needs no Service Bus queue. Optional queues `identity-lifecycle-acks` and `pocketquests-lifecycle` use bounded delivery, duplicate detection and dead-lettering on the existing Standard namespace. No topic is necessary for the current per-consumer queue contract. This leaf intentionally does not enable delivery or set consumer configuration. Product consumers, acknowledgments, scoped grants, Graph lifecycle consent, poison-message handling and erasure-safe restore are separate acceptance gates. Do not call this production-ready after queue creation or successful sign-in.

Approve current regional costs before creation; no dollar quote was verified. New baseline costs are SQL Basic, Standard Key Vault and API consumption. Shared ACR/broker/log usage can grow; runner/network alternatives are unpriced. No dedicated networking resources are silently introduced to preserve reuse of the healthy existing environment.

## Offline validation

Use the pinned Bicep 0.48.1 and Azure CLI 2.91.0 setup described in [Pulse offline verification](../pulse/README.md#offline-verification), then `python3 -m unittest discover -s tests -v`. The Identity tests compile real templates, verify no default writes/grants, explicit named traffic, health probes, SQL auth/firewall defaults and bounded queues. The real CLI test transports a group name containing spaces into the compiled parameter value. No login or deployment is used by these tests. Existing shared Key Vault diagnostic-settings API linter warnings are unchanged.
