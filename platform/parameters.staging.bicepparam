// platform/parameters.staging.bicepparam  (ADR-0077 packet 14)
// Per-env values for the shared-foundation deploy into rg-hd-platform-staging.
// No secret values (D7 / invariant 91).
using './main.bicep'

param env = 'staging'

param location = 'eastus'

param tags = {
  'hd:node': 'honeydrunk-infrastructure'
  'hd:env': 'staging'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'core-infra'
  'hd:dr-tier': 'T1'
  'hd:adr': 'ADR-0077'
}
