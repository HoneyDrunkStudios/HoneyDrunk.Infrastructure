"""Offline deployment ownership tests. No Azure login, deployment, or what-if."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('resolver', ROOT / 'scripts/resolve-deploy-target.py')
resolver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolver)


class DispatchTests(unittest.TestCase):
    def test_default_pulse_does_not_request_app_update(self):
        result = resolver.resolve('dev', 'node', 'pulse')
        self.assertEqual(result['additional-parameters'], '')
        self.assertEqual(result['resource-group'], 'rg-hd-pulse-dev')

    def test_bootstrap_is_explicit(self):
        result = resolver.resolve('dev', 'node', 'pulse', bootstrap=True)
        self.assertEqual(result['additional-parameters'], 'bootstrap=true')

    def test_maintenance_transports_exact_image_and_named_revision(self):
        result = resolver.resolve('dev', 'node', 'pulse', manage_app=True,
                                  app_image='acr.example.io/pulse@sha256:1234',
                                  traffic_revision='ca-hd-pulse-dev--known-good')
        tokens = result['additional-parameters'].split()
        self.assertEqual(len(tokens), 1)
        name, payload = tokens[0].split('=', 1)
        self.assertEqual(name, 'appUpdate')
        self.assertEqual(json.loads(payload), {
            'image': 'acr.example.io/pulse@sha256:1234',
            'trafficRevision': 'ca-hd-pulse-dev--known-good'})

    def test_existing_azure_generated_numeric_revision_is_accepted(self):
        result = resolver.resolve('dev', 'node', 'pulse', manage_app=True,
                                  app_image='acr.io/pulse:v1',
                                  traffic_revision='ca-hd-pulse-dev--0000001')
        update = json.loads(result['additional-parameters'].split('=', 1)[1])
        self.assertEqual(update['trafficRevision'], 'ca-hd-pulse-dev--0000001')

    def test_rejects_unsafe_or_incomplete_maintenance(self):
        cases = [
            {}, {'app_image': 'acr.io/app:v1'},
            {'traffic_revision': 'ca-hd-pulse-dev--good'},
            {'app_image': 'acr.io/app:v1', 'traffic_revision': 'latest'},
            {'app_image': 'acr.io/app:v1', 'traffic_revision': 'ca-hd-pulse-prod--good'},
            {'app_image': 'acr.io/app:v1', 'traffic_revision': 'ca-hd-other-dev--good'},
            {'app_image': 'acr.io/app:v1', 'traffic_revision': 'ca-hd-pulse-dev--bad--suffix'},
            {'app_image': 'acr.io/app:v1 extra=true', 'traffic_revision': 'ca-hd-pulse-dev--good'},
            {'app_image': '$(touch /tmp/no)', 'traffic_revision': 'ca-hd-pulse-dev--good'},
            {'app_image': 'acr.io/app:v1', 'traffic_revision': 'ca-hd-pulse-dev--good\nbootstrap=true'},
        ]
        for case in cases:
            with self.subTest(case=case), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'pulse', manage_app=True, **case)

    def test_rejects_ambiguous_ownership(self):
        for args in [dict(bootstrap=True, manage_app=True),
                     dict(bootstrap=True, app_image='acr.io/pulse:v1'),
                     dict(app_image='acr.io/pulse:v1'),
                     dict(traffic_revision='ca-hd-pulse-dev--good')]:
            with self.subTest(args=args), self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', 'pulse', **args)
        for target, node in [('platform', ''), ('node', 'other')]:
            with self.assertRaises(ValueError):
                resolver.resolve('dev', target, node, manage_app=True,
                                 app_image='acr.io/pulse:v1', traffic_revision='ca-hd-pulse-dev--good')

    def test_unrelated_platform_and_node_behavior_preserved(self):
        self.assertEqual(resolver.resolve('prod', 'platform', bootstrap=True)['additional-parameters'], '')
        self.assertEqual(resolver.resolve('dev', 'node', 'notify', bootstrap=True)['additional-parameters'], 'bootstrap=true')
        for node in ['', '../pulse', 'pulse\nbootstrap=true', 'Pulse']:
            with self.assertRaises(ValueError):
                resolver.resolve('dev', 'node', node)

    def test_real_cli_outputs_and_missing_parameter_file(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'outputs'
            env = {**os.environ, 'ENV': 'dev', 'TARGET': 'node', 'NODE': 'pulse',
                   'BOOTSTRAP': 'false', 'MANAGE_APP': 'false', 'APP_IMAGE': '',
                   'TRAFFIC_REVISION': '', 'GITHUB_OUTPUT': str(output)}
            cmd = ['python3', str(ROOT / 'scripts/resolve-deploy-target.py')]
            result = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('additional-parameters=\n', output.read_text())
            output.unlink()
            result = subprocess.run(cmd, cwd=ROOT, env={**env, 'ENV': 'prod'}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)  # no Pulse prod parameter file yet
            self.assertFalse(output.exists())


class CompiledBicepTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.compiler = os.getenv('BICEP_BIN') or shutil.which('bicep')
        if not cls.compiler:
            raise RuntimeError('Install the official Bicep CLI or set BICEP_BIN; compile tests must not be skipped')
        cls.temp = tempfile.TemporaryDirectory()
        cls.pulse = cls.build('nodes/pulse/main.bicep', 'pulse')
        cls.module = cls.build('modules/compute/containerApp.bicep', 'module')

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def build(cls, source, stem):
        dest = Path(cls.temp.name) / f'{stem}.json'
        result = subprocess.run([cls.compiler, 'build', str(ROOT / source), '--outfile', str(dest)],
                                capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return json.loads(dest.read_text())

    def test_default_pulse_only_references_existing_app(self):
        self.assertIs(self.pulse['parameters']['bootstrap']['defaultValue'], False)
        self.assertIs(self.pulse['parameters']['appUpdate']['nullable'], True)
        self.assertEqual(self.pulse['variables']['manageContainerApp'],
                         "[or(parameters('bootstrap'), not(equals(parameters('appUpdate'), null())))]")
        self.assertIs(self.pulse['resources']['existingApp']['existing'], True)
        self.assertEqual(self.pulse['resources']['app']['condition'], "[variables('manageContainerApp')]")
        writable_apps = [r for r in self.pulse['resources'].values()
                         if r['type'] == 'Microsoft.App/containerApps' and not r.get('existing')]
        self.assertEqual(writable_apps, [])
        self.assertEqual(self.pulse['parameters']['image']['defaultValue'], '')

    def test_bootstrap_and_maintenance_pin_named_traffic(self):
        params = self.pulse['resources']['app']['properties']['parameters']
        entry, = params['traffic']['value']
        self.assertIs(entry['latestRevision'], False)
        self.assertEqual(entry['weight'], 100)
        self.assertEqual(entry['revisionName'],
                         "[if(parameters('bootstrap'), format('{0}--{1}', variables('appName'), variables('bootstrapRevisionSuffix')), coalesce(tryGet(parameters('appUpdate'), 'trafficRevision'), ''))]")
        self.assertEqual(self.pulse['variables']['bootstrapRevisionSuffix'], 'bootstrap')
        self.assertIn("variables('bootstrapRevisionSuffix')", params['revisionSuffix'])
        self.assertEqual(self.pulse['variables']['effectiveImage'],
                         "[if(parameters('bootstrap'), variables('bootstrapImage'), coalesce(tryGet(parameters('appUpdate'), 'image'), parameters('image')))]")

    def test_app_update_is_sealed_and_requires_nonempty_fields(self):
        update = self.pulse['definitions']['containerAppUpdate']
        self.assertIs(update['additionalProperties'], False)
        self.assertEqual(set(update['properties']), {'image', 'trafficRevision'})
        for field in update['properties'].values():
            self.assertEqual(field['minLength'], 1)
            self.assertFalse(field.get('nullable', False))

    def test_generic_module_remains_backward_compatible(self):
        self.assertEqual(self.module['parameters']['traffic']['defaultValue'],
                         [{'latestRevision': True, 'weight': 100}])
        self.assertEqual(self.module['parameters']['revisionSuffix']['defaultValue'], '')
        app = self.module['resources']['containerApp']['properties']
        self.assertEqual(app['configuration']['activeRevisionsMode'], 'Multiple')
        self.assertEqual(app['configuration']['ingress']['traffic'], "[parameters('traffic')]")
        self.assertIn("if(empty(parameters('revisionSuffix')), createObject()", app['template'])

    def test_legacy_image_parameter_still_builds_without_enabling_app_writes(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'tests') as directory:
            source = Path(directory) / 'legacy.bicepparam'
            source.write_text("using '../../nodes/pulse/main.bicep'\nparam env = 'dev'\n"
                              "param tags = {}\nparam image = 'acr.io/pulse:historical'\n")
            dest = Path(self.temp.name) / 'legacy.json'
            result = subprocess.run([self.compiler, 'build-params', str(source), '--outfile', str(dest)],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            parameters = json.loads(dest.read_text())['parameters']
            self.assertEqual(parameters['image']['value'], 'acr.io/pulse:historical')
            self.assertNotIn('appUpdate', parameters)
            self.assertNotIn('bootstrap', parameters)
            # Legacy image is deliberately absent from the only app-write gate.
            self.assertNotIn("parameters('image')", self.pulse['variables']['manageContainerApp'])

    def test_invalid_app_update_parameter_files_fail_compilation(self):
        invalid = ["{ image: 'acr.io/pulse:v1' }",
                   "{ trafficRevision: 'ca-hd-pulse-dev--good' }",
                   "{ image: ''\n trafficRevision: 'ca-hd-pulse-dev--good' }",
                   "{ image: 'acr.io/pulse:v1'\n trafficRevision: '' }",
                   "{ image: 'acr.io/pulse:v1'\n trafficRevision: 'ca-hd-pulse-dev--good'\n latestRevision: true }"]
        with tempfile.TemporaryDirectory(dir=ROOT / 'tests') as directory:
            for index, update in enumerate(invalid):
                with self.subTest(update=update):
                    source = Path(directory) / f'invalid-{index}.bicepparam'
                    source.write_text("using '../../nodes/pulse/main.bicep'\nparam env = 'dev'\n"
                                      "param tags = {}\nparam image = 'acr.io/pulse:legacy'\n"
                                      f"param appUpdate = {update}\n")
                    result = subprocess.run([self.compiler, 'build-params', str(source), '--stdout'],
                                            capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_all_checked_in_parameter_files_build(self):
        for source in sorted(ROOT.glob('**/*.bicepparam')):
            with self.subTest(source=source.relative_to(ROOT)):
                dest = Path(self.temp.name) / f'{source.parent.name}-{source.stem}.json'
                result = subprocess.run([self.compiler, 'build-params', str(source), '--outfile', str(dest)],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                if source.parent.name == 'pulse':
                    parsed = json.loads(dest.read_text())
                    self.assertNotIn('image', parsed['parameters'])
                    self.assertNotIn('appUpdate', parsed['parameters'])
                    self.assertNotIn('bootstrap', parsed['parameters'])


if __name__ == '__main__':
    unittest.main()
