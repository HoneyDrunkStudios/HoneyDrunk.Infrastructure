# Development state bootstrap

This independent root creates only the dedicated state resource group, account,
seven private containers, seven container-scoped operator grants, previous-version
retention and a delete lock. It uses the management API to create containers.
It never creates application resources or registers providers.

The initial backend is **local** because the remote backend does not exist yet.
`Review-Bootstrap.ps1` copies the exact configuration/lock into a new private review
directory, fixes the local state path there and saves a real create-only plan plus
hash manifest. It never applies. Treat every file there as private. Place it on the
operator's protected disk outside Git and shared artifact folders; do not enable
Terraform debug logging. Inputs are the approved subscription, workforce tenant,
existing operator object ID, and one public IPv4 (without `/32`).

```powershell
./bootstrap/state/Review-Bootstrap.ps1 -Inputs <private-inputs.tfvars.json> -ReviewDirectory <new-private-directory>
```

After approval of the exact saved plan, verify its SHA256 against the reviewed
manifest and run Terraform **from its copied configuration**, applying only that
saved plan with `-lock-timeout=60s`. Never run `apply` without the plan argument or
use `-target`, `-lock=false`, an import or a newly generated plan under old approval.
A collision, partial apply or provider failure requires a fresh review; no retries
with wider network/permissions or an alternate paid SKU.

## Recovery verification and migration

After apply and role propagation, use Azure CLI `--auth-mode login` to create a
uniquely named **scratch** blob in `tfstate-bootstrap-dev`. Upload a second version,
download the first by version ID and compare SHA256. Acquire a finite 60-second
lease, prove an overwrite without that lease fails, then release the lease and
delete only the scratch blob. Never experiment on a state blob. Record these
results before migrating local state; a mocked test is not recovery evidence.

For migration, replace only the copied bootstrap configuration's local backend
block with `backend "azurerm" {}`. Supply a private backend file selecting
`sthdtfstatedev`, `tfstate-bootstrap-dev`, `dev/bootstrap.tfstate`, the approved
subscription/tenant, `use_azuread_auth=true`, and `use_cli=true`. Run
`terraform init -migrate-state` interactively after reviewing its source/destination;
do not use force-copy. Verify lineage/serial/resource IDs and a no-change plan.
Retain the protected local recovery copy until that verification succeeds.

Application roots use the six other containers. They cannot delete their backend.
The resource-group lock and lifecycle protection prevent ordinary deletion, but
authorized administrators can remove protections; removal is a separate recovery
operation. Current state blobs never expire. Previous versions expire after 90
days, and deleted blobs/containers have 30-day recovery retention.

An IP change is a newly reviewed firewall update using the retained bootstrap
state, not permission to recreate the backend or widen access. No shared-key/SAS
fallback, subscription data grant or all-networks exception exists.
