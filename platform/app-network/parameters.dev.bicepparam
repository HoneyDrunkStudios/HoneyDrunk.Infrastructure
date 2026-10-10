using './main.bicep'
param env = 'dev'
param location = 'eastus2'
param tags = {
  'hd:node': 'honeydrunk-infrastructure'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'core-infra'
  'hd:dr-tier': 'T1'
  'hd:adr': 'ADR-0077'
}
// networkSetup intentionally omitted: no CIDR is selected and no network is written.
