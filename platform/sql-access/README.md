# Identity access to Central US SQL

The October 11 approved revision places Identity App Service and SQL in Central US while preserving the existing East US 2 network and other resources. The app has no VNet integration; the approved scoped public-egress design creates no subnet rule.

After creating the stopped app, this root reads the current outbound IPv4 addresses of exactly `app-hd-identity-dev` in `rg-hd-identity-dev`. Each address gets one SQL firewall rule with identical start/end addresses. Empty addresses, wrong app region and the all-Azure `0.0.0.0` bypass are rejected. SQL remains Entra-only and the runtime uses managed identity and TLS. The outbound IPs are shared App Service infrastructure addresses, not a per-app identity boundary; SQL authentication remains required.

Creation order: SQL server, Identity database/vault, stopped Identity app and runtime grants, then this firewall root. No manually guessed IP or broad Azure range is accepted. The existing East US 2 network and its unused SQL service endpoint remain managed and unchanged.

Re-plan/apply this root after an App Service hosting/tier change that changes egress addresses, and test SQL reachability before accepting the release. Address drift is detected at plan time, not repaired automatically. The independently approved temporary `operator_ipv4` rule remains null outside a schema maintenance window.

This root has independent state and no deployment workflow. Read [migration and approval boundaries](../../docs/terraform-migration.md). The server remains protected; removing an obsolete IP rule only removes that rule.

The owner separately approved persistent workstation/SSMS access on October 11.
`workstation_access` defaults to null and accepts an explicitly chosen rule name
and one public IPv4. Import an existing portal-created rule at that exact name,
then review an in-place update narrowing start/end to the same address. This is
independent of `operator_ipv4`: closing a schema window does not remove approved
workstation access. SQL still requires Entra authentication and existing database
permissions. If the ISP address changes, verify the new address and update the
explicit Terraform input; do not broaden the range or discover it dynamically
inside Terraform. Current workstation access is recorded in the private live
inputs and state, not this example.
