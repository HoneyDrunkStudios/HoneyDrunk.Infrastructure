# Pulse adoption only

The live Container App and Key Vault are not managed resources in this root.
Only the existing app is read, supplying its system identity to the three exact
existing RG-scoped role assignments. The app's image/settings/revisions/traffic
remain owned by Pulse CD. No bootstrap or maintenance flag can issue an app PUT.

Before approved import, inventory each role assignment UUID/scope and populate
`existing_assignment_names` (`acr_pull`, `configuration_reader`, `vault_reader`).
Preserve scopes and IDs; do not invent GUIDs or recreate grants. A confidential
post-import plan must have no changes. See [adoption](../../docs/terraform-migration.md).
