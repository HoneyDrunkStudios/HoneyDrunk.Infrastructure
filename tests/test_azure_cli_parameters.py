"""Real Azure CLI/Bicep parameter interpretation, without a deployment or login.

Install azure-cli==2.91.0 and set BICEP_BIN to Bicep 0.48.1. This exercises
the installed resource module's .bicepparam entrypoint, not a replacement
parser and not a test-generated BICEP_PARAMETERS_OVERRIDES environment.
Only the compiler execution boundary is wrapped: it executes the real binary
with --no-restore and rejects unexpected commands. Python network access fails.
"""
import argparse
from contextlib import ExitStack
import importlib.metadata
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from identity_inputs import APP_UPDATE


ROOT = Path(__file__).resolve().parents[1]
AZURE_CLI_VERSION = '2.91.0'
BICEP_VERSION = '0.48.1'
spec = importlib.util.spec_from_file_location('cli_resolver', ROOT / 'scripts/resolve-deploy-target.py')
resolver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resolver)

# Mirrors word splitting with globbing disabled and a quoted array in the
# reusable workflow; this is a transport harness, not execution of its YAML:
# https://github.com/HoneyDrunkStudios/HoneyDrunk.Actions/blob/f681148c87fe606e43b84d6e53f93bb0080978b8/.github/workflows/job-deploy-bicep.yml
SHELL_TRANSPORT = r'''
set -euo pipefail
EXTRA_ARGS=()
if [ -n "$EXTRA" ]; then
  set -f
  for tok in $EXTRA; do
    if ! printf '%s' "$tok" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+$'; then
      exit 1
    fi
    EXTRA_ARGS+=(--parameters "$tok")
  done
  set +f
fi
printf '%s\0' --parameters "$PARAMS" "${EXTRA_ARGS[@]}"
'''


class AzureCliParameterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if importlib.metadata.version('azure-cli') != AZURE_CLI_VERSION:
            raise RuntimeError(f'Install azure-cli=={AZURE_CLI_VERSION}; CLI contract tests must not be skipped')
        compiler = os.getenv('BICEP_BIN') or shutil.which('bicep')
        if not compiler or not Path(compiler).is_file():
            raise RuntimeError('Set BICEP_BIN to the official Bicep 0.48.1 executable')

        cls.context = ExitStack()
        cls.addClassCleanup(cls.context.close)
        directory = Path(cls.context.enter_context(tempfile.TemporaryDirectory()))
        binary_dir = directory / 'bin'
        binary_dir.mkdir()
        (binary_dir / 'bicep').symlink_to(Path(compiler).resolve())
        cls.context.enter_context(patch.dict(os.environ, {
            'AZURE_CONFIG_DIR': str(directory / 'azure'),
            'AZURE_CORE_COLLECT_TELEMETRY': 'false',
            'PATH': str(binary_dir) + os.pathsep + os.environ.get('PATH', ''),
            'DOTNET_BUNDLE_EXTRACT_BASE_DIR': str(directory / 'dotnet'),
        }))
        # A developer's environment must not inject an override into the first
        # compile. The CLI itself creates this variable for the second compile.
        os.environ.pop('BICEP_PARAMETERS_OVERRIDES', None)

        for target in ('socket.socket.connect', 'socket.socket.connect_ex',
                       'socket.create_connection', 'socket.getaddrinfo',
                       'requests.sessions.Session.request'):
            cls.context.enter_context(patch(target, side_effect=AssertionError('Network access is forbidden in this test')))

        # Import only the offline resource implementation. Do not construct an
        # AzCli instance, load an account/profile, or invoke deployment commands.
        from azure.cli.command_modules.resource import _bicep, custom
        from knack.config import CLIConfig
        cls.resource = custom
        config = CLIConfig(config_dir=str(directory / 'azure'),
                           config_env_var_prefix='HD_OFFLINE_TEST', use_local_config=False)
        config.set_value('bicep', 'use_binary_from_path', 'true')
        config.set_value('bicep', 'check_version', 'false')
        cls.command = SimpleNamespace(cli_ctx=SimpleNamespace(config=config))
        cls.compiler_calls = []
        real_run = _bicep._run_command

        def offline_compiler(binary, args, custom_env=None):
            if binary != 'bicep':
                raise AssertionError(f'Unexpected compiler executable: {binary}')
            if args == ['--version']:
                return real_run(binary, args, custom_env)
            if not (len(args) == 3 and args[0] == 'build-params' and args[2] == '--stdout'):
                raise AssertionError(f'Unexpected compiler command: {args}')
            cls.compiler_calls.append((list(args), dict(custom_env or {})))
            # This is the only altered execution boundary. No parsing or
            # compiler output is mocked, and no external module can restore.
            return real_run(binary, [*args, '--no-restore'], custom_env)

        cls.context.enter_context(patch.object(_bicep, '_run_command', side_effect=offline_compiler))
        version = _bicep.run_bicep_command(cls.command.cli_ctx, ['--version'])
        if not version.startswith(f'Bicep CLI version {BICEP_VERSION} '):
            raise RuntimeError(f'Expected Bicep {BICEP_VERSION}, got {version.strip()}')
        print(f'Offline parameter transport: azure-cli {AZURE_CLI_VERSION}; {version.strip()}', flush=True)

    def prepare(self, extra='', parameter_file=None):
        parameter_file = parameter_file or ROOT / 'nodes/pulse/parameters.dev.bicepparam'
        transported = subprocess.run(
            ['bash', '-c', SHELL_TRANSPORT], check=True, capture_output=True,
            env={**os.environ, 'EXTRA': extra, 'PARAMS': str(parameter_file)})
        argv = transported.stdout.decode().rstrip('\0').split('\0')
        # Azure CLI 2.91.0 resource/_params.py registers --parameters with
        # action='append', nargs='+'. Preserve that exact argument grouping.
        parser = argparse.ArgumentParser()
        parser.add_argument('--parameters', action='append', nargs='+')
        parameter_lists = parser.parse_args(argv).parameters
        self.assertEqual(parameter_lists[0], [str(parameter_file)])
        if extra:
            self.assertEqual(parameter_lists[1:], [[token] for token in extra.split()])
        self.compiler_calls.clear()
        template, template_spec, parameters = self.resource._parse_bicepparam_file(
            self.command, template_file=None, parameters=parameter_lists)
        self.assertIsNone(template_spec)
        expected_type = 'appConfiguration' if parameter_file.parent.name == 'identity' else 'containerAppUpdate'
        self.assertEqual(json.loads(template)['parameters']['appUpdate']['$ref'], f'#/definitions/{expected_type}')
        self.assertNotIn('BICEP_PARAMETERS_OVERRIDES', self.compiler_calls[0][1])
        return json.loads(parameters)['parameters']

    def test_identity_database_settings_preserve_spaces_through_real_cli(self):
        expected = {'administratorLogin': 'Identity SQL Admins',
                    'administratorObjectId': '11111111-1111-1111-1111-111111111111',
                    'firewallRules': []}
        result = resolver.resolve('dev', 'node', 'identity',
                                  identity_parameters=json.dumps({'databaseSetup': expected}))
        parameters = self.prepare(result['additional-parameters'], ROOT / 'nodes/identity/parameters.dev.bicepparam')
        self.assertEqual(parameters['databaseSetup']['value'], expected)

    def test_resolver_shell_and_cli_preserve_exact_app_update_object(self):
        for revision in ('ca-hd-pulse-dev--known-good', 'ca-hd-pulse-dev--0000001'):
            with self.subTest(revision=revision):
                expected = {'image': 'acr.example.io/pulse@sha256:' + 'a' * 64,
                            'trafficRevision': revision}
                result = resolver.resolve('dev', 'node', 'pulse', manage_app=True,
                                          app_image=expected['image'], traffic_revision=revision)
                parameters = self.prepare(result['additional-parameters'])
                self.assertEqual(parameters['appUpdate'], {'value': expected})
                self.assertIsInstance(parameters['appUpdate']['value'], dict)
                self.assertNotIn('bootstrap', parameters)
                self.assertEqual(len(self.compiler_calls), 2)
                # Inspect the override produced by the real CLI, rather than
                # supplying it ourselves and assuming CLI interpretation.
                self.assertEqual(json.loads(self.compiler_calls[1][1]['BICEP_PARAMETERS_OVERRIDES']),
                                 {'appUpdate': expected})

    def test_identity_complete_app_update_round_trips_through_real_cli(self):
        result = resolver.resolve('dev', 'node', 'identity',
                                  identity_parameters=json.dumps({'appUpdate': APP_UPDATE}))
        parameters = self.prepare(result['additional-parameters'], ROOT / 'nodes/identity/parameters.dev.bicepparam')
        self.assertEqual(parameters['appUpdate']['value'], APP_UPDATE)
        self.assertEqual(len(self.compiler_calls), 2)
        self.assertEqual(json.loads(self.compiler_calls[1][1]['BICEP_PARAMETERS_OVERRIDES']),
                         {'appUpdate': APP_UPDATE})
        self.assertNotIn('bootstrap', parameters)

    def test_default_and_bootstrap_remain_distinct(self):
        default = resolver.resolve('dev', 'node', 'pulse')
        parameters = self.prepare(default['additional-parameters'])
        for name in ('appUpdate', 'bootstrap', 'image'):
            self.assertNotIn(name, parameters)
        bootstrap = resolver.resolve('dev', 'node', 'pulse', bootstrap=True)
        parameters = self.prepare(bootstrap['additional-parameters'])
        self.assertIs(parameters['bootstrap']['value'], True)
        self.assertNotIn('appUpdate', parameters)

    def test_later_inline_object_overrides_parameter_file_object(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'tests') as directory:
            source = Path(directory) / 'previous.bicepparam'
            source.write_text("using '../../nodes/pulse/main.bicep'\nparam env = 'dev'\nparam tags = {}\n"
                              "param appUpdate = { image: 'acr.io/pulse:old'\n"
                              "trafficRevision: 'ca-hd-pulse-dev--old' }\n")
            expected = {'image': 'acr.io/pulse:new', 'trafficRevision': 'ca-hd-pulse-dev--new'}
            extra = 'appUpdate=' + json.dumps(expected, separators=(',', ':'))
            self.assertEqual(self.prepare(extra, source)['appUpdate'], {'value': expected})

    def test_invalid_inline_objects_fail_real_compiler_validation(self):
        from azure.cli.core.azclierror import UnclassifiedUserFault
        invalid = [
            ({'image': 'acr.io/pulse:v1'}, 'BCP035'),
            ({'trafficRevision': 'ca-hd-pulse-dev--good'}, 'BCP035'),
            ({'image': '', 'trafficRevision': 'ca-hd-pulse-dev--good'}, 'BCP333'),
            ({'image': 'acr.io/pulse:v1', 'trafficRevision': ''}, 'BCP333'),
            ({'image': 'acr.io/pulse:v1', 'trafficRevision': 'ca-hd-pulse-dev--good',
              'latestRevision': True}, 'BCP037'),
            ({'image': 123, 'trafficRevision': 'ca-hd-pulse-dev--good'}, 'BCP036'),
        ]
        for value, diagnostic in invalid:
            with self.subTest(value=value), self.assertRaisesRegex(UnclassifiedUserFault, diagnostic):
                self.prepare('appUpdate=' + json.dumps(value, separators=(',', ':')))

    def test_malformed_json_fails_cli_interpretation(self):
        from knack.util import CLIError
        with self.assertRaises(CLIError):
            self.prepare('appUpdate={invalid-json}')
        # The original file compiled, but malformed JSON must never reach the
        # second Bicep invocation as a made-up string/object override.
        self.assertEqual(len(self.compiler_calls), 1)


if __name__ == '__main__':
    unittest.main()
