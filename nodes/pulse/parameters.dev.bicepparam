// nodes/pulse/parameters.dev.bicepparam  (ADR-0077 — Pulse Node)
// Per-env values for the Pulse Container App deploy into rg-hd-pulse-dev.
// No secret values (D7 / invariant 91) — secrets are Key Vault references
// resolved at runtime by the app's managed identity.
using './main.bicep'

param env = 'dev'

// No image or traffic snapshot belongs in this file. Pulse CD owns releases.
// Default deploys reference the existing app; initialization/maintenance needs
// an explicit reviewed appUpdate (see README).

// location omitted — inherits the target RG's region (rg-hd-pulse-dev = East US 2).

param tags = {
  'hd:node': 'honeydrunk-pulse'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'observability'
  'hd:dr-tier': 'T2'
  'hd:adr': 'ADR-0077'
}
