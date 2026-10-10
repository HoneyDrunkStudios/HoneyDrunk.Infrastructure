# Node composition

Node roots own product resources; shared SQL/server/network resources remain in
`platform/`. All roots are development-only. See the [root index](../README.md)
and [adoption runbook](../docs/terraform-migration.md). Separate states express
ownership and approval boundaries; removing a Terraform resource requests deletion.
