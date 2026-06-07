// nodes/pulse/parameters.dev.bicepparam  (ADR-0077 — Pulse Node)
// Per-env values for the Pulse Container App deploy into rg-hd-pulse-dev.
// No secret values (D7 / invariant 91) — secrets are Key Vault references
// resolved at runtime by the app's managed identity.
using './main.bicep'

param env = 'dev'

// The current dev pulse-collector image. Owned here until Pulse CD owns image
// promotion; matches the image live on ca-hd-pulse-dev at migration time so the
// recreate on the new shared environment is byte-identical bar the environment.
param image = 'acrhdshareddev.azurecr.io/honeydrunk-pulse-collector:dev-45377959a43f6698f8fa42ca3a58eb5d13a42c47'

// location omitted — inherits the target RG's region (rg-hd-pulse-dev = East US 2).

param tags = {
  'hd:node': 'honeydrunk-pulse'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'observability'
  'hd:dr-tier': 'T2'
  'hd:adr': 'ADR-0077'
}
