# State and authentication

The independent development backend is deployed in `rg-hd-tfstate-dev` using
`sthdtfstatedev`: Entra authentication, TLS 1.2+, private containers, disabled
shared-key/anonymous access, versioning, 30-day blob/container soft delete and
90-day previous-version retention. A CanNotDelete lock protects the group. The
public endpoint denies all networks except the approved operator IPv4; no trusted
service bypass or all-networks fallback is enabled.

Sixteen private containers and sixteen operator grants are owned by
`bootstrap/state`. Each grant is container-scoped. See the
[exact root/container/key map](terraform-adoption.md#state-and-source-boundaries).
The bootstrap root now uses its existing Azure backend, not local state.

Private backend configuration selects the actual account, container and key:

```hcl
resource_group_name  = "rg-hd-tfstate-dev"
storage_account_name = "sthdtfstatedev"
container_name       = "tfstate-platform-dev"
key                  = "dev/platform.tfstate"
subscription_id      = "82073da5-bd6d-4874-947e-73b791054cbc"
tenant_id            = "f5654adb-2a4c-4317-9217-09ef32ccdd3a"
use_azuread_auth      = true
use_cli              = true
```

Use the exact key for the selected root. Never repurpose a container or silently
switch state through workspaces. The customer Graph provider uses the customer
tenant independently of the workforce-authenticated Azure backend. Future CI/OIDC
access remains a separate reviewed setup; a source merge grants no data access.

AzureRM provider registration is disabled and AzAPI skips registration. An IP
change requires a reviewed bootstrap firewall update, not backend recreation.
No key/SAS fallback, subscription Blob grant, forced copy or unlock bypass exists.

State, backups, saved plans, plan JSON and backend metadata are sensitive. Do not
put them in Git, chat, PR logs or shared artifacts. Disable Terraform debug logging.
Use a bounded lock timeout, exact saved-plan apply and post-apply no-change check.
Provider-read credentials may enter encrypted state even with ID-only outputs.

See [recovery and adoption acceptance](terraform-adoption.md#planning-apply-and-recovery).
Initial bootstrap history and retained local recovery copies are private operational
evidence; they must never overwrite a newer remote state. The old create-only local
bootstrap helper is retired after successful migration.
