# App Service integration network

This isolated platform leaf owns proposed `vnet-hd-apps-dev` / `snet-app-service`
in existing `rg-hd-platform-dev`, East US 2. It is not imported by broad platform IaC.
Read the [connectivity and approval plan](../sql/connectivity.md).

`target=platform-app-network`, `env=dev`, `network-parameters` accepts nonsecret
`networkSetup` with explicit `addressPrefix` and `subnetPrefix`. No CIDRs are
checked in. Empty input compiles to no writes; output IDs are planned references.
The resolver validates canonical RFC1918 IPv4, containment and at least /28;
/26 is recommended. Actual overlap checks, names, budget and apply need approval.

The subnet delegates to `Microsoft.Web/serverFarms` and enables `Microsoft.Sql`.
No NAT, PIP, LB, private endpoint, role assignment or existing ACA mutation occurs.
SQL subnet authorization is separately controlled by `platform/sql` with
`allowAppServiceSubnet=true`; it requires the service endpoint to exist.

The module declares the complete new VNet/subnet collection. Before later changes,
reconcile every existing subnet; never overwrite separately added subnet ownership.
Only dev has checked-in parameters. Production is not implemented or authorized.
