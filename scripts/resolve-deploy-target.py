#!/usr/bin/env python3
"""Resolve dispatch inputs without Azure access; reject unsafe app ownership mixes."""
import json
import os
import re
from pathlib import Path


def resolve(env, target, node='', bootstrap=False, manage_app=False,
            app_image='', traffic_revision=''):
    if env not in {'dev', 'staging', 'prod'}:
        raise ValueError('env must be dev, staging, or prod')
    overrides = ''
    if target == 'platform':
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
        raise ValueError('target must be platform or node')
    return {'template-path': f'{directory}/main.bicep',
            'parameters-path': f'{directory}/parameters.{env}.bicepparam',
            'resource-group': group, 'additional-parameters': overrides}


def main():
    try:
        result = resolve(os.environ['ENV'], os.environ['TARGET'], os.getenv('NODE', ''),
                         os.getenv('BOOTSTRAP', 'false') == 'true',
                         os.getenv('MANAGE_APP', 'false') == 'true',
                         os.getenv('APP_IMAGE', ''), os.getenv('TRAFFIC_REVISION', ''))
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
