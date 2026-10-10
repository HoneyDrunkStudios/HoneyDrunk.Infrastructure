# Dedicated application network

Required `network_cidr` and `subnet_cidr` have no defaults. Verify overlap with Azure, operator and planned peering networks before approving them.

This root has independent state and no deployment workflow. Read [migration and approval boundaries](../../docs/terraform-migration.md) first. Dev / East US 2 only.
