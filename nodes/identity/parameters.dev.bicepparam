using './main.bicep'

param env = 'dev'
param location = 'eastus2'
param tags = {
  'hd:node': 'honeydrunk-identity'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'identity'
  'hd:dr-tier': 'T2'
  'hd:adr': 'ADR-0077'
}
// Default is a read of the existing app. First provisioning requires a separately approved network, then reviewed
// provisionDatabase/provisionVault/bootstrap parameters, then separate appUpdate.
// The shared server is a separate platform/sql deployment; no admin/firewall here.
// No credentials, app IDs, firewall grants, image snapshot or selected CIDRs.
