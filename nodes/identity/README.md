# Identity development compute

This root describes `asp-hd-identity-dev` (one Linux B1 worker) and
`app-hd-identity-dev` in the existing `rg-hd-identity-dev`, East US 2. The approved
subnet ID must refer to `vnet-hd-apps-dev/snet-app-service`, with App Service
delegation and the classic Microsoft.Sql endpoint. No address is selected here.

First creation is a **stopped** public placeholder at an immutable digest, with
system MI, HTTPS/TLS 1.2, FTP/SCM basic publishing disabled, always-on and VNet
application routing. Image pulls retain the public route. No certificate, secret,
role grant, SQL contained user or live application is configured.

Terraform permanently manages infrastructure fields. `ignore_changes` delegates
image/application stack, app settings, enabled state and health path to approved
runtime initialization/CD. Normal Terraform runs cannot replay a historical image
or settings. Do not toggle resource ownership with `count`, remove these ignores
casually, or bootstrap an existing serving app.

## Runtime initialization remains separately approved

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

Initialization needs an approved configuration operation, exact values, quiesced
writers, grants and readiness evidence before enabling the app. Actions PR #218
only handles image release/explicit rollback and does not authorize these setup
steps. The source migration does not enable a SQL publisher: exact executor and
all-DDL-writer freeze remain unapproved. SQL schema/readiness and the Identity
application PR dependencies must be resolved before a serving API is claimed.

B1 has no slots and no second instance for health failover. Direct updates or
retained-image rollback may interrupt service. No production rollout is selected.
