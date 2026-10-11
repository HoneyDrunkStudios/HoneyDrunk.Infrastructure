# Identity database

Required `server_id` points to the platform-owned shared server. Basic 2 GiB, local backups, seven-day retention. This does not publish schema or authorize SQL execution.

This root has independent state and no deployment workflow. Read [migration and approval boundaries](../../docs/terraform-migration.md) first. Dev / Central US only, inherited from the shared SQL server. Identity App Service is also in Central US. The existing network, vault and shared services remain in East US 2.
