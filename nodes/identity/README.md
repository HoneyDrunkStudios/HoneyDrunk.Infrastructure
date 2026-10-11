# Identity development compute

This root describes `asp-hd-identity-dev` (one Linux B1 worker) and
`app-hd-identity-dev` in the existing `rg-hd-identity-dev`, Central US. The existing
East US 2 VNet, vault, registry and resource groups stay unchanged. Regional VNet
integration cannot use that network, so `subnet_id` is explicitly null and VNet
route-all is disabled. The SQL-access root reads this app's actual outbound IPv4
addresses and grants individual firewall rules. No new network or broad SQL bypass
is created. SQL authentication still uses the app's managed identity.

First creation is a **stopped** public placeholder at an immutable digest, with
system MI, HTTPS/TLS 1.2, FTP/SCM basic publishing disabled, always-on and public
application egress. Image pulls retain the public route. This root also grants
the app's system identity AcrPull on the shared registry and Secrets User on its
own vault. No certificate, secret, SQL contained user or live application is configured.

This root also preserves registration of `Microsoft.Quota`, required to inspect
and request the approved single B1 worker after Azure returned a regional quota
of zero. Registration itself does not allocate workers or raise quota. The quota
request in East US 2 failed. Central US B1 and total regional quota were both
verified at 30 with zero used before this approved revision. No Microsoft support
ticket is requested or submitted; the existing registration remains preserved.

Terraform permanently manages infrastructure fields. `ignore_changes` delegates
image/application stack, app settings, enabled state and health path to approved
runtime initialization/CD. Normal Terraform runs cannot replay a historical image
or settings. Do not toggle resource ownership with `count`, remove these ignores
casually, or bootstrap an existing serving app.

## Runtime ownership and initialization

The configuration contract from Infrastructure PR #13 is retained here:

- `ASPNETCORE_ENVIRONMENT=Production`, `ASPNETCORE_HTTP_PORTS=8080`,
  `HONEYDRUNK_NODE_ID=honeydrunk-identity`; container port `8080`, warmup and health
  `/health`, accepted warmup status `200`, startup timeout `600`.
- `AZURE_KEYVAULT_URI` points to the approved Identity vault. The SQL connection
  uses `sql-hd-shared-dev.database.windows.net`, `sqldb-hd-identity-dev`,
  `Authentication=Active Directory Managed Identity`, encryption enabled,
  `TrustServerCertificate=False`, and connection timeout `15`. No password.
- Reviewed Entra Authority/Issuer/Audience/MobileClientId/ApiScope and indexed
  `Cors__AllowedOrigins__N`, plus OTLP endpoint. These are mandatory product
  configuration, not invented defaults.
- Graph `CredentialMode=Certificate`, External ID Graph tenant/client IDs and
  `CertificateSecretName`; certificate material stays in Key Vault and the
  external tenant app. Workforce Azure tenant and External ID tenant differ.
- Approved shared ACR immutable image, MI-based AcrPull and own-vault access.
  Capture current runtime settings privately before maintenance; do not put them
  in Terraform variables/state to operate as a settings editor.

The separately approved October 11 initialization completed with quiesced writers,
an exact-script empty-database executor, scoped SQL permissions, a vault-backed
Graph certificate and an immutable application image. Real customer sign-in,
SQL persistence and restart readiness were verified. The initialization runbook
and executor belong to HoneyDrunk.Identity; the general SQL publisher remains
disabled. Source publication does not rerun that initialization.

The shared Actions image-release workflow only handles image updates and explicit
rollback. Future schema or credential changes require their own reviewed operation.
Azure backup restoration and native product/device acceptance remain outstanding.

B1 has no slots and no second instance for health failover. Direct updates or
retained-image rollback may interrupt service. No production rollout is selected.
