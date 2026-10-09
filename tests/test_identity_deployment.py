"""Compile real templates to protect Identity ownership and permission boundaries."""
import json
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('identity_resolver', ROOT / 'scripts/resolve-deploy-target.py')
resolver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolver)


class IdentityDispatchTests(unittest.TestCase):
    def test_reviewed_database_settings_survive_token_transport(self):
        settings = {'databaseSetup': {'administratorLogin': 'Identity SQL Admins',
                    'administratorObjectId': '11111111-1111-1111-1111-111111111111',
                    'firewallRules': []}, 'provisionVault': True}
        result = resolver.resolve('dev', 'node', 'identity', bootstrap=True,
                                  identity_parameters=json.dumps(settings))
        tokens = result['additional-parameters'].split()
        self.assertEqual(tokens[0], 'bootstrap=true')
        restored = {key: json.loads(value) for key, value in (item.split('=', 1) for item in tokens[1:])}
        self.assertEqual(restored, settings)

    def test_rejects_cross_node_inputs_secret_values_and_firewall_bypass(self):
        with self.assertRaises(ValueError):
            resolver.resolve('dev', 'node', 'pulse', identity_parameters='{}')
        for settings in [{'certificateBase64': 'must-not-be-an-input'}, {'provisionVault': 'true'},
                         {'databaseSetup': {'administratorLogin': 'admins',
                          'administratorObjectId': '11111111-1111-1111-1111-111111111111',
                          'firewallRules': [{'name': 'bypass', 'startIpAddress': '0.0.0.0', 'endIpAddress': '0.0.0.0'}]}}]:
            with self.subTest(settings=settings), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'identity', identity_parameters=json.dumps(settings))


class IdentityDeploymentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.templates = {}
        for key, path in {
            'identity': 'nodes/identity/main.bicep',
            'sql': 'modules/data/sqlDatabase.bicep',
            'queue': 'modules/messaging/serviceBusQueue.bicep',
            'app': 'modules/compute/containerApp.bicep',
        }.items():
            output = Path(cls.temp.name) / f'{key}.json'
            subprocess.run([os.environ['BICEP_BIN'], 'build', str(ROOT / path),
                            '--outfile', str(output)], check=True, capture_output=True)
            cls.templates[key] = json.loads(output.read_text(encoding='utf-8-sig'))

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_steady_state_cannot_write_app_or_provision_dependencies(self):
        leaf = self.templates['identity']
        for key in ['bootstrap', 'provisionVault', 'provisionLifecycleQueues']:
            self.assertIs(leaf['parameters'][key]['defaultValue'], False)
        for key in ['appUpdate', 'databaseSetup']:
            self.assertIs(leaf['parameters'][key]['nullable'], True)
        self.assertIs(leaf['resources']['existingApp']['existing'], True)
        self.assertEqual(leaf['resources']['app']['condition'], '[variables(\'manageApp\')]')
        self.assertIn("parameters('databaseSetup')", leaf['resources']['database']['condition'])
        self.assertNotIn('Microsoft.Authorization/roleAssignments', json.dumps(leaf))

    def test_app_uses_named_traffic_and_distinct_health_probes(self):
        parameters = self.templates['identity']['resources']['app']['properties']['parameters']
        traffic = parameters['traffic']['value'][0]
        self.assertIs(traffic['latestRevision'], False)
        self.assertEqual(traffic['weight'], 100)
        source = (ROOT / 'nodes/identity/main.bicep').read_text()
        self.assertIn("path: '/health/live'", source)
        self.assertIn("path: '/health'", source)
        self.assertNotIn('Lifecycle__ServiceBusNamespace', source)
        self.assertNotIn('ca-hd-pulse', source)

    def test_sql_uses_entra_only_and_restrictive_defaults(self):
        template = self.templates['sql']
        resources = template['resources']
        if isinstance(resources, list):
            resources = {r['type'].split('/')[-1]: r for r in resources}
            server, database = resources['servers'], resources['databases']
        else:
            server, database = resources['server'], resources['database']
        self.assertTrue(server['properties']['administrators']['azureADOnlyAuthentication'])
        self.assertNotIn('administratorLoginPassword', server['properties'])
        self.assertEqual(template['parameters']['firewallRules']['defaultValue'], [])
        self.assertEqual(database['sku']['name'], 'Basic')

    def test_queue_has_bounded_retry_and_dead_lettering(self):
        resources = self.templates['queue']['resources']
        queue = resources['queue'] if isinstance(resources, dict) else next(r for r in resources if r['type'].endswith('/queues'))
        properties = queue['properties']
        self.assertEqual(properties['maxDeliveryCount'], 10)
        self.assertTrue(properties['deadLetteringOnMessageExpiration'])
        self.assertTrue(properties['requiresDuplicateDetection'])


if __name__ == '__main__':
    unittest.main()
