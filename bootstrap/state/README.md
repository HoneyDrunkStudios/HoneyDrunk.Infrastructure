# Protected development state backend

This root owns the deployed state group/account, sixteen private containers,
sixteen container-scoped operator grants, retention policy and deletion lock.
It uses the existing Azure backend at `tfstate-bootstrap-dev/dev/bootstrap.tfstate`.

The initial local bootstrap and scratch recovery probe completed before state
migration. Do not rerun a create-only bootstrap against an empty state. The former
local planning helper is retired. See [state configuration](../../docs/terraform-state.md)
and [recovery](../../docs/terraform-adoption.md#planning-apply-and-recovery).

Inputs remain the exact development subscription, workforce tenant, operator object
ID and approved single public IPv4. An access/network change requires its own
saved-plan review. This root never owns application resources or registers providers.
