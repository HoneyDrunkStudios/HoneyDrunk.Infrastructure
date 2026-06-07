// platform/parameters.dev.bicepparam  (ADR-0077 packet 14)
// Per-env values for the shared-foundation deploy into rg-hd-platform-dev.
// No secret values (D7 / invariant 91).
using './main.bicep'

param env = 'dev'

// location omitted — inherits the target RG's region (resourceGroup().location),
// i.e. East US 2 for rg-hd-platform-dev.

param tags = {
  'hd:node': 'honeydrunk-infrastructure'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'core-infra'
  'hd:dr-tier': 'T1'
  'hd:adr': 'ADR-0077'
}
