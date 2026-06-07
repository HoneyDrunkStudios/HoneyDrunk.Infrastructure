// platform/parameters.prod.bicepparam  (ADR-0077 packet 14)
// Per-env values for the shared-foundation deploy into rg-hd-platform-prod.
// No secret values (D7 / invariant 91).
using './main.bicep'

param env = 'prod'

// location omitted — inherits the target RG's region (resourceGroup().location).

param tags = {
  'hd:node': 'honeydrunk-infrastructure'
  'hd:env': 'prod'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'core-infra'
  'hd:dr-tier': 'T1'
  'hd:adr': 'ADR-0077'
}
