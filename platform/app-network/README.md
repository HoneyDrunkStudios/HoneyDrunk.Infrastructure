# Dedicated application network

Required `network_cidr` and `subnet_cidr` have no defaults. Verify overlap with Azure, operator and planned peering networks before approving them.

This root has independent state and no deployment workflow. Read [migration and approval boundaries](../../docs/terraform-migration.md) first. Dev / East US 2 only.

The October 11 deployment registered `Microsoft.Network` and created this VNet and subnet. These resources are live and managed by this root. Initialize the existing Azure backend listed in the [state map](../../docs/terraform-adoption.md) before planning; never use an empty local state. Provider auto-registration remains disabled; the registration is protected against destruction/unregistration. The Central US Identity app does not attach to this East US 2 network.
