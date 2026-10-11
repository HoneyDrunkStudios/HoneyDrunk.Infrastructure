# Shared SQL logical server

`administrator_name` and `administrator_object_id` identify an existing approved workforce Entra group. Alternatively, `create_administrator_group=true` creates the named security group with the verified `administrator_member_object_id` as its sole initial member and owner. The group belongs to this SQL root and is protected against destruction. Entra-only auth; no SQL password, product database or firewall bypass.

This root explicitly manages registration of `Microsoft.Sql`, verified unregistered during the October 11 review. Auto-registration remains disabled. Registration requires subscription-level permission and is protected against unregistering through destroy. Do not apply this proposal without reviewing the saved plan.

This root has independent state and no deployment workflow. Read [migration and approval boundaries](../../docs/terraform-migration.md) first. Dev / Central US only. The October 11 deployment selected Central US after East US 2 rejected new SQL server creation. Identity hosting subsequently received separate approval for Central US too; the existing East US 2 estate and workforce administrator group are preserved.
