using './main.bicep'

param env = 'dev'
param tags = {
  'hd:node': 'honeydrunk-identity'
  'hd:env': 'dev'
  'hd:owner': 'honeydrunkstudios'
  'hd:cost-center': 'identity'
  'hd:dr-tier': 'T2'
  'hd:adr': 'ADR-0077'
}
// Default is a read of the existing app. First provisioning requires reviewed
// databaseSetup/provisionVault/bootstrap parameters, then separate appUpdate.
// No credentials, app IDs, firewall grants, image snapshot or traffic snapshot.
