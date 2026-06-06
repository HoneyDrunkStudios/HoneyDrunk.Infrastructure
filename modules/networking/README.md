# modules/networking

Per-concern Bicep modules for **networking** (ADR-0077 D2).

**Owns:** virtual networks, subnets, private endpoints, network security groups,
public IPs, DNS zones.

**Example resources:** `vnet`, `subnet`, `privateDnsZone`, `dnsRecord`.

**Status:** empty-state. Module bodies land when a consumer first needs them (the
initial six-concern set is ADR-0077 packet 13; networking modules land when a
Node or the `platform/` layer first requires them).

**Consumed by** local relative path, e.g. from a node leaf template:

```bicep
module vnet '../../modules/networking/vnet.bicep' = { ... }
```

No registry, no `br:` references — see the [repo README](../../README.md).
