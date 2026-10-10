#!/usr/bin/env python3
"""Resolve dispatch inputs without Azure access; reject unsafe app ownership mixes."""
import json
import os
import re
import ipaddress
import uuid
from pathlib import Path
from urllib.parse import urlsplit


def resolve(env, target, node='', bootstrap=False, manage_app=False,
            app_image='', traffic_revision='', identity_parameters='', sql_parameters=''):
    if env not in {'dev', 'staging', 'prod'}:
        raise ValueError('env must be dev, staging, or prod')
    if identity_parameters and (env, target, node) != ('dev', 'node', 'identity'):
        raise ValueError('identity-parameters is only valid for node=identity, env=dev')
    if sql_parameters and (env, target) != ('dev', 'platform-sql'):
        raise ValueError('sql-parameters is only valid for target=platform-sql, env=dev')
    overrides = ''
    if target == 'platform-sql':
        if env != 'dev' or node or bootstrap or manage_app or app_image or traffic_revision:
            raise ValueError('platform-sql is dev-only and cannot accept node/app inputs')
        directory, group = 'platform/sql', 'rg-hd-platform-dev'
    elif target == 'platform':
        if manage_app or app_image or traffic_revision:
            raise ValueError('app maintenance inputs require target=node, node=pulse')
        # Preserve the existing caller behavior: bootstrap is ignored for platform.
        directory, group = 'platform', f'rg-hd-platform-{env}'
    elif target == 'node':
        if not re.fullmatch(r'[a-z][a-z0-9-]{0,28}', node):
            raise ValueError('target=node requires a valid lowercase node name')
        directory, group = f'nodes/{node}', f'rg-hd-{node}-{env}'
        if bootstrap and (manage_app or app_image or traffic_revision):
            raise ValueError('bootstrap cannot be combined with app maintenance inputs')
        if manage_app:
            if node != 'pulse':
                raise ValueError('manage-app is currently supported only by node=pulse')
            # Compact JSON is transported as one key=value token by job-deploy-bicep.
            # Restrict input characters, not shell quoting or eval, to avoid flags,
            # whitespace, expression injection and extra parameter tokens.
            if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9._/:@-]*', app_image):
                raise ValueError('manage-app requires a nonempty image reference without spaces or shell syntax')
            # Existing Azure-generated revisions may start with a digit (0000001).
            # This is a lookup identity, not a new custom revision suffix.
            prefix = f'ca-hd-pulse-{env}--'
            suffix = traffic_revision.removeprefix(prefix)
            if (not traffic_revision.startswith(prefix)
                    or not re.fullmatch(r'[a-z0-9][a-z0-9-]{0,63}', suffix)
                    or '--' in suffix or suffix.endswith('-')):
                raise ValueError('manage-app requires the full named known-good revision for the selected Pulse app; latest is not accepted')
            update = json.dumps({'image': app_image, 'trafficRevision': traffic_revision},
                                separators=(',', ':'))
            overrides = f'appUpdate={update}'
        elif app_image or traffic_revision:
            raise ValueError('app-image and traffic-revision require manage-app=true')
        elif bootstrap:
            overrides = 'bootstrap=true'
    else:
        raise ValueError('target must be platform, platform-sql or node')
    if identity_parameters:
        settings = json.loads(identity_parameters)
        validate_identity_settings(settings, bootstrap)
    elif sql_parameters:
        settings = json.loads(sql_parameters)
        validate_sql_settings(settings)
    else:
        settings = {}
    if settings:
        tokens = [f'{key}={json.dumps(value, separators=(",", ":")).replace(" ", chr(92) + "u0020")}'
                  for key, value in settings.items()]
        overrides = ' '.join(filter(None, [overrides, *tokens]))
    return {'template-path': f'{directory}/main.bicep',
            'parameters-path': f'{directory}/parameters.{env}.bicepparam',
            'resource-group': group, 'additional-parameters': overrides}


def validate_sql_settings(settings):
    """Server administration and firewall inputs belong only to platform/sql."""
    if not isinstance(settings, dict) or settings.keys() - {'serverSetup'}:
        raise ValueError('sql-parameters contains unsupported fields')
    database = settings.get('serverSetup')
    if database is not None:
        if not isinstance(database, dict) or set(database) != {'administratorLogin', 'administratorObjectId', 'firewallRules'}:
            raise ValueError('serverSetup requires the approved administrator and firewall rules')
        if not isinstance(database['administratorLogin'], str) or not database['administratorLogin'].strip():
            raise ValueError('An approved administrator group name is required')
        administrator_id = database['administratorObjectId']
        if not isinstance(administrator_id, str):
            raise ValueError('An approved canonical administrator object ID is required')
        parsed_id = uuid.UUID(administrator_id)
        if not parsed_id.int or administrator_id.lower() != str(parsed_id):
            raise ValueError('An approved canonical administrator object ID is required')
        if not isinstance(database['firewallRules'], list):
            raise ValueError('firewallRules must be an explicit list')
        names = set()
        for rule in database['firewallRules']:
            if not isinstance(rule, dict) or set(rule) != {'name', 'startIpAddress', 'endIpAddress'}:
                raise ValueError('Unexpected SQL firewall rule fields')
            if (not isinstance(rule['name'], str)
                    or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,127}', rule['name'])
                    or rule['name'].casefold() in names):
                raise ValueError('SQL firewall names must be unique simple names of 1-128 characters')
            names.add(rule['name'].casefold())
            if any(not isinstance(rule[key], str) for key in ['startIpAddress', 'endIpAddress']):
                raise ValueError('SQL firewall addresses must be explicit IPv4 strings')
            start, end = [ipaddress.IPv4Address(rule[key]) for key in ['startIpAddress', 'endIpAddress']]
            if start.is_unspecified or start > end:
                raise ValueError('SQL firewall must use ordered, explicit addresses; no Azure-services bypass')


def validate_identity_settings(settings, bootstrap):
    """Accept only node-owned nonsecret configuration before Azure login."""
    allowed = {'provisionDatabase', 'provisionVault', 'provisionLifecycleQueues', 'appUpdate'}
    if not isinstance(settings, dict) or settings.keys() - allowed:
        raise ValueError('identity-parameters contains unsupported fields')
    for key in ['provisionDatabase', 'provisionVault', 'provisionLifecycleQueues']:
        if key in settings and type(settings[key]) is not bool:
            raise ValueError(f'{key} must be a boolean')
    update = settings.get('appUpdate')
    if update is not None:
        required = {'image', 'trafficRevision', 'authority', 'issuer', 'audience', 'mobileClientId',
                    'apiScope', 'graphTenantId', 'graphClientId', 'graphCertificateSecretName',
                    'allowedOrigins', 'otlpEndpoint'}
        if not isinstance(update, dict) or set(update) != required:
            raise ValueError('appUpdate requires the complete nonsecret Identity configuration')
        if bootstrap or any(settings.get(key) for key in ['provisionDatabase', 'provisionVault', 'provisionLifecycleQueues']):
            raise ValueError('Initialize dependencies first; do not combine appUpdate with resource setup')
        if any(not isinstance(value, str) or not value.strip() for key, value in update.items() if key != 'allowedOrigins'):
            raise ValueError('App configuration values must be nonempty strings')
        if not isinstance(update['allowedOrigins'], list) or not all(isinstance(origin, str) for origin in update['allowedOrigins']):
            raise ValueError('allowedOrigins must be a list of exact browser origins')
        for origin in update['allowedOrigins']:
            parsed = urlsplit(origin)
            # Accessing port also rejects nonnumeric/out-of-range port values.
            port = parsed.port
            if (parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password
                    or parsed.path or parsed.query or parsed.fragment or '*' in origin
                    or any(character.isspace() for character in origin) or '\\' in origin
                    or (port is None and parsed.netloc.endswith(':'))):
                raise ValueError('allowedOrigins must contain exact HTTPS origins without paths or credentials')
        suffix = update['trafficRevision'].removeprefix('ca-hd-identity-dev--')
        if (not re.fullmatch(r'ca-hd-identity-dev--[a-z0-9][a-z0-9-]{0,63}', update['trafficRevision'])
                or '--' in suffix or suffix.endswith('-')):
            raise ValueError('Identity maintenance requires its full known-good revision name')
        if not re.fullmatch(r'acrhdshareddev\.azurecr\.io/honeydrunk-identity-api@sha256:[a-f0-9]{64}', update['image']):
            raise ValueError('Identity maintenance requires a reviewed ACR image digest')
        if not re.fullmatch(r'[A-Za-z0-9-]{1,127}', update['graphCertificateSecretName']):
            raise ValueError('Provide a versionless secret name, never a certificate value or version')


def main():
    try:
        result = resolve(os.environ['ENV'], os.environ['TARGET'], os.getenv('NODE', ''),
                         os.getenv('BOOTSTRAP', 'false') == 'true',
                         os.getenv('MANAGE_APP', 'false') == 'true',
                         os.getenv('APP_IMAGE', ''), os.getenv('TRAFFIC_REVISION', ''),
                         os.getenv('IDENTITY_PARAMETERS', ''), os.getenv('SQL_PARAMETERS', ''))
        for key in ('template-path', 'parameters-path'):
            if not Path(result[key]).is_file():
                raise ValueError(f'{key} does not exist: {result[key]}')
    except (KeyError, ValueError) as exc:
        print(f'::error::{exc}')
        raise SystemExit(1) from exc
    with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
        for key, value in result.items():
            output.write(f'{key}={value}\n')
    print(f"Resolved: {result['template-path']} in {result['resource-group']}")


if __name__ == '__main__':
    main()
