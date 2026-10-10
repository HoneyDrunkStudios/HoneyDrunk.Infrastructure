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
        for root in ['identity', 'identity-data', 'identity-vault', 'identity-messaging', 'pulse']:
            tags = config(f'nodes/{root}/main.tf')['locals'][0]['tags']
            self.assertEqual(tags['hd:dr-tier'], 'T2')
            self.assertEqual(tags['hd:cost-center'], 'observability' if root == 'pulse' else 'identity')
        self.assertEqual(config('platform/main.tf')['locals'][0]['tags']['hd:dr-tier'], 'T1')

    def test_pulse_cannot_write_app_or_vault(self):
        pulse = config('nodes/pulse/main.tf')
        self.assertNotIn('resource', pulse)
        sources = {module['source'] for item in pulse['module'] for module in item.values()}
        self.assertEqual(sources, {'../../modules/identity/role-assignment'})
        self.assertEqual(set(pulse['data'][0]), {'azurerm_container_app'})

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
        self.assertEqual(len(roots), 9)
        for root in roots:
            data = config(f'{root}/main.tf')
            for module in data.get('module', []):
                for body in module.values():
                    self.assertNotIn('count', body)
            versions = config(f'{root}/versions.tf')
            self.assertEqual(versions['provider'][0]['azurerm']['resource_provider_registrations'], 'none')
            self.assertTrue(any('backend' in item for item in versions['terraform']))
        self.assertFalse((ROOT / '.github/workflows/deploy.yml').exists())
        self.assertEqual(list(ROOT.rglob('*.bicep')), [])

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
