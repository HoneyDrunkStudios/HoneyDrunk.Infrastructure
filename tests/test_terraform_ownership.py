"""Assert ownership/approval invariants across composed roots, not live Azure."""
import json
import os
from pathlib import Path
import unittest
import subprocess
import sys
import textwrap

import hcl2

ROOT = Path(__file__).parents[1]


def config(path):
    with (ROOT / path).open(encoding='utf-8') as stream:
        return hcl2.load(stream)


class TerraformOwnershipTests(unittest.TestCase):
    def test_required_legacy_context_fails_for_missing_failed_or_skipped_checks(self):
        workflow = (ROOT / '.github/workflows/pr.yml').read_text()
        self.assertIn('name: Bicep Lint / Bicep Lint', workflow)
        script = textwrap.dedent(workflow.split('        run: |\n', 1)[1])
        for state in ['success', 'failure', 'cancelled', 'skipped']:
            result = subprocess.run([sys.executable, '-c', script], capture_output=True, text=True,
                                    env={**os.environ, 'RESULTS': json.dumps({'terraform':{'result':state}, 'secret-scan':{'result':'success'}})})
            self.assertEqual(result.returncode == 0, state == 'success')
        missing = subprocess.run([sys.executable, '-c', script], capture_output=True,
                                 env={**os.environ, 'RESULTS': '{}'})
        self.assertNotEqual(missing.returncode, 0)

    def test_existing_cost_and_recovery_tags_are_preserved(self):
        for root in ['identity', 'identity-data', 'identity-vault', 'identity-messaging']:
            tags = config(f'nodes/{root}/main.tf')['locals'][0]['tags']
            self.assertEqual(tags['hd:dr-tier'], 'T2')
            self.assertEqual(tags['hd:cost-center'], 'identity')
        platform = config('platform/main.tf')['resource']
        workspace = next(r['azurerm_log_analytics_workspace'] for r in platform if 'azurerm_log_analytics_workspace' in r)
        self.assertEqual(workspace['log_hd_shared_dev']['tags']['hd:dr-tier'], 'T1')

    def test_adopted_recoverable_resources_never_automatically_purge(self):
        # prevent_destroy disappears when a block is removed; provider behavior
        # must still retain recovery instead of turning deletion into a purge.
        for root in ['nodes/pulse-runtime', 'nodes/notify', 'nodes/automation']:
            provider = config(f'{root}/versions.tf')['provider'][0]['azurerm']
            vault = provider['features'][0]['key_vault'][0]
            self.assertFalse(vault['purge_soft_delete_on_destroy'])
            self.assertFalse(vault['recover_soft_deleted_key_vaults'])
        features = config('platform/versions.tf')['provider'][0]['azurerm']['features'][0]
        self.assertFalse(features['app_configuration'][0]['purge_soft_delete_on_destroy'])
        self.assertFalse(features['app_configuration'][0]['recover_soft_deleted'])
        self.assertFalse(features['log_analytics_workspace'][0]['permanently_delete_on_destroy'])

    def test_pulse_adoption_preserves_release_owned_fields(self):
        pulse = config('nodes/pulse-runtime/main.tf')['resource']
        app = next(r['azurerm_container_app'] for r in pulse if 'azurerm_container_app' in r)['ca_hd_pulse_dev']
        self.assertEqual(set(app['lifecycle'][0]['ignore_changes']), {
            '${secret}', '${template[0].container[0].image}', '${template[0].container[0].env}',
            '${template[0].revision_suffix}', '${ingress[0].traffic_weight}', '${registry[0].identity}',
        })
        self.assertTrue(app['lifecycle'][0]['prevent_destroy'])
        self.assertFalse((ROOT / 'nodes/pulse').exists(), 'Legacy grant root would create a second owner')

    def test_identity_data_cannot_write_sql_server_admin_or_network(self):
        data = config('nodes/identity-data/main.tf')
        self.assertNotIn('resource', data)
        self.assertEqual(data['module'][0]['database']['source'], '../../modules/data/sql-database')
        resources = config('modules/data/sql-database/main.tf')['resource']
        self.assertEqual([next(iter(item)) for item in resources], ['azurerm_mssql_database'])

    def test_runtime_configuration_cannot_be_replayed_by_infrastructure(self):
        app = config('modules/compute/app-service/main.tf')['resource'][0]['azurerm_linux_web_app']['this']
        self.assertFalse(app['enabled'])
        self.assertEqual(set(app['lifecycle'][0]['ignore_changes']), {
            '${enabled}', '${app_settings}', '${site_config[0].application_stack}', '${site_config[0].health_check_path}',
        })
        self.assertTrue(app['lifecycle'][0]['prevent_destroy'])

    def test_no_sql_executor_firewall_bypass_or_credential_resources(self):
        forbidden = {'azurerm_mssql_firewall_rule', 'azurerm_key_vault_secret', 'azurerm_key_vault_certificate',
                     'azurerm_app_configuration_key', 'null_resource', 'terraform_data'}
        for file in (ROOT / 'modules').glob('*/*/main.tf'):
            for item in config(file.relative_to(ROOT))['resource']:
                resource_type = next(iter(item))
                self.assertNotIn(resource_type, forbidden)
                for body in item[resource_type].values():
                    self.assertNotIn('provisioner', body)
                    self.assertNotIn('count', body)
                    for credential in ['administrator_login_password', 'administrator_login_password_wo']:
                        self.assertNotIn(credential, body)

    def test_roots_have_no_destroy_switch_or_deployment_trigger(self):
        roots = json.loads((ROOT / 'terraform-roots.json').read_text())
        self.assertEqual(len(roots), 19)
        for root in roots:
            data = config(f'{root}/main.tf')
            for module in data.get('module', []):
                for body in module.values():
                    self.assertNotIn('count', body)
            versions = config(f'{root}/versions.tf')
            for entry in versions['provider']:
                if 'azurerm' in entry:
                    self.assertEqual(entry['azurerm']['resource_provider_registrations'], 'none')
                if 'azapi' in entry:
                    self.assertTrue(entry['azapi']['skip_provider_registration'])
            self.assertTrue(any('backend' in item for item in versions['terraform']))
        self.assertFalse((ROOT / '.github/workflows/deploy.yml').exists())
        self.assertEqual(list(ROOT.rglob('*.bicep')), [])

    def test_adoption_has_one_protected_owner_per_exact_import_id(self):
        manifest = json.loads((ROOT / 'adoption-manifest.json').read_text())
        identities = [item['id'].lower() for item in manifest]
        self.assertEqual(len(identities), len(set(identities)))
        addresses = [(item['root'], item['address']) for item in manifest]
        self.assertEqual(len(addresses), len(set(addresses)))
        for root in {item['root'] for item in manifest}:
            declared = {}
            for item in config(f'{root}/main.tf')['resource']:
                for typ, resources in item.items():
                    for name, body in resources.items():
                        declared[f'{typ}.{name}'] = body
                        self.assertTrue(body['lifecycle'][0]['prevent_destroy'])
                        self.assertNotEqual(body['lifecycle'][0].get('ignore_changes'), '${all}')
            expected = {item['address'] for item in manifest if item['root'] == root}
            self.assertEqual(set(declared), expected)

    def test_imported_runtime_certificate_preserves_write_only_fields(self):
        certificate = config('directory/customer-applications/runtime-certificate.tf')['resource'][0]['azuread_application_certificate']['identity_runtime_20261011']
        self.assertTrue(certificate['lifecycle'][0]['prevent_destroy'])
        self.assertEqual(set(certificate['lifecycle'][0]['ignore_changes']), {'${value}', '${encoding}'})

    def test_notify_secrets_stay_out_of_source(self):
        resources = config('nodes/notify/main.tf')['resource']
        app = next(r['azurerm_function_app_flex_consumption'] for r in resources if 'azurerm_function_app_flex_consumption' in r)['func_hd_notify_dev']
        self.assertEqual(app['app_settings'], {})
        self.assertEqual(app['storage_access_key'], '${azurerm_storage_account.sthdnotifydev.primary_access_key}')
        self.assertIn('${app_settings}', app['lifecycle'][0]['ignore_changes'])

    def test_composition_preserves_shared_ownership_and_no_identity_grants(self):
        for root in ['identity', 'identity-data', 'identity-vault', 'identity-messaging']:
            main = config(f'nodes/{root}/main.tf')
            self.assertNotIn('resource', main)
            for item in main['module']:
                for body in item.values():
                    self.assertNotIn('role-assignment', body['source'])
                    self.assertNotIn('sql-server', body['source'])


if __name__ == '__main__':
    unittest.main()
