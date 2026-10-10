"""Compile real templates to protect Identity ownership and permission boundaries."""
import json
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from identity_inputs import APP_UPDATE

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('identity_resolver', ROOT / 'scripts/resolve-deploy-target.py')
resolver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolver)


class IdentityDispatchTests(unittest.TestCase):
    def test_rejects_invalid_app_configuration(self):
        cases = {
            'image': ['acrhdshareddev.azurecr.io/honeydrunk-identity-api:latest',
                      'acrhdshareddev.azurecr.io/honeydrunk-identity-api@sha256:' + 'a' * 63,
                      'other.azurecr.io/honeydrunk-identity-api@sha256:' + 'a' * 64],
            'trafficRevision': ['latest', 'ca-hd-pulse-dev--good', 'ca-hd-identity-dev--bad--suffix',
                                'ca-hd-identity-dev--bad-', 'ca-hd-identity-dev--UPPER'],
            'graphCertificateSecretName': ['', 'secret/version', 'secret_value', 'a' * 128],
            'allowedOrigins': ['https://example.com', [123], ['http://example.com'],
                               ['https://example.com/path'], ['https://example.com/'],
                               ['https://example.com?query'], ['https://example.com#fragment'],
                               ['https://user:password@example.com'], ['https://*.example.com'],
                               ['https://example.com:99999'], ['https://example.com:']],
            'audience': ['', 123],
        }
        for field, values in cases.items():
            for value in values:
                with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                    resolver.resolve('dev', 'node', 'identity',
                                     identity_parameters=json.dumps({'appUpdate': {**APP_UPDATE, field: value}}))
        for update in [{key: value for key, value in APP_UPDATE.items() if key != 'issuer'},
                       {**APP_UPDATE, 'unexpected': 'value'}]:
            with self.subTest(update=update), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'identity', identity_parameters=json.dumps({'appUpdate': update}))

    def test_rejects_app_update_combined_with_provisioning(self):
        for setup in [{'provisionVault': True}, {'provisionLifecycleQueues': True}, {'provisionDatabase': True}]:
            with self.subTest(setup=setup), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'identity',
                                 identity_parameters=json.dumps({**setup, 'appUpdate': APP_UPDATE}))
        with self.assertRaises(ValueError):
            resolver.resolve('dev', 'node', 'identity', bootstrap=True,
                             identity_parameters=json.dumps({'appUpdate': APP_UPDATE}))

    def test_rejects_invalid_sql_administrators_and_reversed_firewall_range(self):
        database = {'administratorLogin': 'Admins', 'administratorObjectId': '11111111-1111-1111-1111-111111111111', 'firewallRules': []}
        for value in ['', 'not-a-guid', '00000000-0000-0000-0000-000000000000', 123,
                      '1' * 32, '{11111111-1111-1111-1111-111111111111}',
                      'urn:uuid:11111111-1111-1111-1111-111111111111']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                resolver.resolve('dev', 'platform-sql', sql_parameters=json.dumps({
                    'serverSetup': {**database, 'administratorObjectId': value}}))
        with self.assertRaises(ValueError):
            resolver.resolve('dev', 'platform-sql', sql_parameters=json.dumps({'serverSetup': {
                **database, 'firewallRules': [{'name': 'reversed', 'startIpAddress': '192.0.2.20',
                                             'endIpAddress': '192.0.2.10'}]}}))

    def test_reviewed_database_settings_survive_token_transport(self):
        settings = {'serverSetup': {'administratorLogin': 'Shared SQL Admins',
                    'administratorObjectId': '11111111-1111-1111-1111-111111111111',
                    'firewallRules': []}}
        result = resolver.resolve('dev', 'platform-sql', sql_parameters=json.dumps(settings))
        tokens = result['additional-parameters'].split()
        self.assertEqual(result['template-path'], 'platform/sql/main.bicep')
        self.assertEqual(result['resource-group'], 'rg-hd-platform-dev')
        restored = {key: json.loads(value) for key, value in (item.split('=', 1) for item in tokens)}
        self.assertEqual(restored, settings)

    def test_rejects_cross_node_inputs_secret_values_and_server_ownership(self):
        with self.assertRaises(ValueError):
            resolver.resolve('dev', 'node', 'pulse', identity_parameters='{}')
        for settings in [{'certificateBase64': 'must-not-be-an-input'}, {'provisionVault': 'true'},
                         {'databaseSetup': {}}, {'serverSetup': {}}, {'provisionDatabase': 'true'}]:
            with self.subTest(settings=settings), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'identity', identity_parameters=json.dumps(settings))

    def test_sql_target_rejects_wrong_scopes_and_app_inputs(self):
        for args in [dict(env='prod', target='platform-sql'),
                     dict(env='dev', target='platform-sql', node='identity'),
                     dict(env='dev', target='platform-sql', bootstrap=True),
                     dict(env='dev', target='platform-sql', manage_app=True),
                     dict(env='dev', target='platform-sql', app_image='image'),
                     dict(env='dev', target='platform-sql', traffic_revision='revision'),
                     dict(env='dev', target='platform', sql_parameters='{}'),
                     dict(env='dev', target='node', node='identity', sql_parameters='{}')]:
            with self.subTest(args=args), self.assertRaises(ValueError):
                resolver.resolve(**args)
        for settings in [[], {'provisionDatabase': True}, {'appUpdate': APP_UPDATE},
                         {'serverSetup': {'administratorLogin': 'incomplete'}},
                         {'serverSetup': {'password': 'never'}}]:
            with self.subTest(settings=settings), self.assertRaises(ValueError):
                resolver.resolve('dev', 'platform-sql', sql_parameters=json.dumps(settings))

    def test_sql_firewall_rejects_bypass_nonstrings_bad_names_and_duplicates(self):
        rule = {'name': 'operator', 'startIpAddress': '192.0.2.10', 'endIpAddress': '192.0.2.10'}
        invalid = [[{**rule, 'startIpAddress': '0.0.0.0'}],
                   [{**rule, 'startIpAddress': 1}], [{**rule, 'endIpAddress': 2}],
                   [{**rule, 'startIpAddress': '::1'}], [{**rule, 'name': ''}],
                   [{**rule, 'name': 'bad name'}], [{**rule, 'name': 123}],
                   [{**rule, 'name': 'a' * 129}], [rule, {**rule, 'name': 'OPERATOR'}]]
        for rules in invalid:
            with self.subTest(rules=rules), self.assertRaises(ValueError):
                resolver.resolve('dev', 'platform-sql', sql_parameters=json.dumps({'serverSetup': {
                    'administratorLogin': 'Shared SQL Admins',
                    'administratorObjectId': '11111111-1111-1111-1111-111111111111', 'firewallRules': rules}}))


class IdentityDeploymentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.templates = {}
        for key, path in {
            'identity': 'nodes/identity/main.bicep',
            'sql': 'modules/data/sqlDatabase.bicep',
            'sqlServer': 'modules/data/sqlServer.bicep',
            'sharedSql': 'platform/sql/main.bicep',
            'queue': 'modules/messaging/serviceBusQueue.bicep',
            'app': 'modules/compute/containerApp.bicep',
        }.items():
            output = Path(cls.temp.name) / f'{key}.json'
            subprocess.run([os.environ['BICEP_BIN'], 'build', str(ROOT / path),
                            '--outfile', str(output)], check=True, capture_output=True)
            cls.templates[key] = json.loads(output.read_text(encoding='utf-8-sig'))
        cls.parameters = {}
        for key, path in {'identity': 'nodes/identity', 'sharedSql': 'platform/sql'}.items():
            output = Path(cls.temp.name) / f'{key}.parameters.json'
            subprocess.run([os.environ['BICEP_BIN'], 'build-params',
                            str(ROOT / path / 'parameters.dev.bicepparam'), '--outfile', str(output)],
                           check=True, capture_output=True)
            cls.parameters[key] = json.loads(output.read_text(encoding='utf-8-sig'))['parameters']

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_steady_state_cannot_write_app_or_provision_dependencies(self):
        leaf = self.templates['identity']
        for key in ['bootstrap', 'provisionDatabase', 'provisionVault', 'provisionLifecycleQueues']:
            self.assertIs(leaf['parameters'][key]['defaultValue'], False)
        for key in ['appUpdate']:
            self.assertIs(leaf['parameters'][key]['nullable'], True)
        self.assertIs(leaf['resources']['existingApp']['existing'], True)
        self.assertEqual(leaf['resources']['app']['condition'], '[variables(\'manageApp\')]')
        self.assertEqual(leaf['resources']['database']['condition'], "[parameters('provisionDatabase')]")
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
        template = self.templates['sqlServer']
        resources = template['resources']
        if isinstance(resources, list):
            resources = {r['type'].split('/')[-1]: r for r in resources}
            server = resources['servers']
        else:
            server = resources['server']
        self.assertTrue(server['properties']['administrators']['azureADOnlyAuthentication'])
        self.assertNotIn('administratorLoginPassword', server['properties'])
        self.assertEqual(template['parameters']['firewallRules']['defaultValue'], [])

    def test_database_cannot_write_shared_server_admin_or_network(self):
        template = self.templates['sql']
        resources = template['resources']
        resources = list(resources.values()) if isinstance(resources, dict) else resources
        writes = [resource for resource in resources if not resource.get('existing')]
        self.assertEqual({r['type'] for r in writes}, {
            'Microsoft.Sql/servers/databases',
            'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies'})
        database = next(r for r in writes if r['type'].endswith('/databases'))
        retention = next(r for r in writes if r['type'].endswith('/backupShortTermRetentionPolicies'))
        self.assertEqual(database['sku'], {'name': 'Basic', 'tier': 'Basic', 'capacity': 5})
        self.assertEqual(database['properties']['maxSizeBytes'], 2147483648)
        self.assertEqual(database['properties']['requestedBackupStorageRedundancy'], 'Local')
        self.assertEqual(retention['properties']['retentionDays'], 7)
        for forbidden in ['administrator', 'firewall', 'roleAssignments', 'pocketquests']:
            self.assertNotIn(forbidden, json.dumps(template))

    def test_shared_server_leaf_has_no_app_database_or_platform_redeployment(self):
        leaf = self.templates['sharedSql']
        self.assertIs(leaf['parameters']['serverSetup']['nullable'], True)
        self.assertEqual(set(leaf['resources']), {'server'})
        self.assertIn("parameters('serverSetup')", leaf['resources']['server']['condition'])
        for forbidden in ['Microsoft.App/', 'Microsoft.Authorization/', 'Microsoft.Sql/servers/databases']:
            self.assertNotIn(forbidden, json.dumps(leaf))
        self.assertEqual(resolver.resolve('dev', 'platform-sql')['additional-parameters'], '')

    def test_database_scope_endpoint_and_tags_preserve_separate_ownership(self):
        leaf = self.templates['identity']
        database = leaf['resources']['database']
        self.assertEqual(database['resourceGroup'], "[variables('platformGroup')]")
        self.assertIn('sql-hd-shared-', database['properties']['parameters']['serverName']['value'])
        self.assertEqual(database['properties']['parameters']['service']['value'], 'identity')
        self.assertEqual(leaf['resources']['server']['resourceGroup'], "[variables('platformGroup')]")
        self.assertIn('sql-hd-shared-', leaf['resources']['server']['name'])
        shared = self.parameters['sharedSql']
        identity = self.parameters['identity']
        self.assertEqual(shared['location']['value'], 'eastus2')
        self.assertEqual(identity['location']['value'], 'eastus2')
        common = {'hd:env': 'dev', 'hd:owner': 'honeydrunkstudios', 'hd:adr': 'ADR-0077'}
        self.assertEqual(shared['tags']['value'], {**common, 'hd:node': 'honeydrunk-infrastructure',
                                                 'hd:cost-center': 'core-infra', 'hd:dr-tier': 'T1'})
        self.assertEqual(identity['tags']['value'], {**common, 'hd:node': 'honeydrunk-identity',
                                                   'hd:cost-center': 'identity', 'hd:dr-tier': 'T2'})

    def test_compiled_probes_respect_container_apps_limits(self):
        leaf = self.templates['identity']
        self.assertIn("variables('runtimeProbes')", json.dumps(leaf['resources']['app']['properties']['parameters']['probes']))
        probes = leaf['variables']['runtimeProbes']
        self.assertEqual({probe['type'] for probe in probes}, {'Startup', 'Liveness', 'Readiness'})
        for probe in probes:
            for field, maximum in [('failureThreshold', 10), ('initialDelaySeconds', 60),
                                   ('periodSeconds', 240), ('timeoutSeconds', 240), ('successThreshold', 10)]:
                if field in probe:
                    with self.subTest(probe=probe['type'], field=field):
                        self.assertGreaterEqual(probe[field], 1)
                        self.assertLessEqual(probe[field], maximum)
            if probe['type'] in {'Startup', 'Liveness'}:
                self.assertEqual(probe.get('successThreshold', 1), 1)
            self.assertEqual(probe['httpGet']['port'], 8080)
            self.assertEqual(probe['httpGet']['path'], '/health' if probe['type'] == 'Readiness' else '/health/live')
        startup = next(probe for probe in probes if probe['type'] == 'Startup')
        self.assertEqual(startup['periodSeconds'] * startup['failureThreshold'], 150)

    def test_queue_has_bounded_retry_and_dead_lettering(self):
        resources = self.templates['queue']['resources']
        queue = resources['queue'] if isinstance(resources, dict) else next(r for r in resources if r['type'].endswith('/queues'))
        properties = queue['properties']
        self.assertEqual(properties['maxDeliveryCount'], 10)
        self.assertTrue(properties['deadLetteringOnMessageExpiration'])
        self.assertTrue(properties['requiresDuplicateDetection'])


if __name__ == '__main__':
    unittest.main()
