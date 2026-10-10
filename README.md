# HoneyDrunk.Infrastructure

Terraform source for the HoneyDrunk Grid's Azure resources. Infrastructure owns
composition; [HoneyDrunk.Actions](https://github.com/HoneyDrunkStudios/HoneyDrunk.Actions)
owns reusable validation and future deployment orchestration. The founder's
October 10 Terraform request replaces the Bicep tool choice for this source
migration. Studio's ADR-0077/invariants amendment must be coordinated before merge.

**Source migration only. No Azure deployment, state adoption or backend has been
enabled.** The former Bicep dispatcher is removed so a merge does not leave two
active infrastructure writers. Git history retains the old implementation.

| Root | Responsibility |
| --- | --- |
| `platform` | Adopt existing shared logs, Container Apps environment, ACR, App Configuration and Service Bus |
| `platform/app-network` | Proposed dedicated App Service VNet/subnet; no default CIDRs |
| `platform/sql` | Proposed shared Entra-only logical SQL server; no passwords/firewall bypass |
| `platform/sql-access` | Separately approved Microsoft.Sql endpoint subnet rule |
| `nodes/identity` | Proposed dedicated Linux B1 plan and stopped placeholder app |
| `nodes/identity-data` | Separate Identity Basic database on the shared server |
| `nodes/identity-vault` | Proposed vault/diagnostics; no secret values or grants |
| `nodes/identity-messaging` | Proposed lifecycle queues; activation/grants unapproved |
| `nodes/pulse` | Existing app read plus adoption of existing role assignments; no app writes |

`modules/{concern}/{module}` contains 18 reusable AzureRM resource modules and
safety tests. All root composition is dev/East US 2. Staging/production need a
separate reviewed design. Resource groups are references, never implicitly created.
Independent state roots replace destructive provision/delete toggles.

## Credential-free validation

Terraform **1.16.5**, AzureRM **5.9.0** and the shared committed provider lock
(Windows/Linux checksums) are pinned. The Actions workflow checks formatting,
initializes with `-backend=false -lockfile=readonly`, validates provider schemas
and executes only mocked plan tests. It verifies every declared test actually ran.
PRs retain the secret scan and add ownership-contract checks; there is no Azure
login, live plan or state/plan artifact.

The existing required check is still named `Bicep Lint / Bicep Lint`. It now
requires both the complete Terraform/ownership validation and secret scan to
succeed; it fails if either is missing, failed, cancelled or skipped. Keep that
compatibility context until a separately approved branch-rule migration. Its
name is not an instruction to run or restore the former Bicep workflow.

Use an isolated Actions checkout at the same SHA as `.github/workflows/pr.yml`:

```powershell
python -m pip install -r <actions-checkout>/.github/config/terraform-requirements.txt
python <actions-checkout>/.github/scripts/terraform_validate.py .
python -m unittest discover -s tests -v
```

The helper stages copies of the root lock in each validated directory. Those
copies, provider caches, private tfvars, backend files, state and plans are ignored.
For individual validation, copy the shared lock first, then initialize with
`-backend=false -lockfile=readonly`, validate and run mocked `terraform test`.
Do not substitute a real `terraform plan` for tests.

## Migration boundary

Read [migration/adoption](docs/terraform-migration.md),
[state/authentication](docs/terraform-state.md) and
[Identity initialization](nodes/identity/README.md) before operational work.
No apply/import workflow is dispatchable. SQL publisher/exact executor and the
all-writer freeze remain unapproved. No price or source definition is spending
permission, and no CI result is live readiness evidence.

AzureRM covers the scope, including stopped Web Apps and Azure Monitor routing;
no AzAPI exception is needed. Provider-read keys/settings can still enter state
despite ID-only outputs. Never place live state or plan JSON in PR logs.
