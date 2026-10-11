# HoneyDrunk.Infrastructure

Terraform source for the HoneyDrunk Azure development estate. Existing resources
are adopted with their IDs, configuration, access and data preserved. The flow
application association is checked for drift but cannot yet be written through the
pinned provider; the disabled subscription remains inaccessible. New Identity
hosting, SQL and networking remain a separate deployment decision.

Start with [estate ownership and runtime exceptions](docs/terraform-adoption.md),
[backend access and recovery](docs/terraform-state.md), and the exact
[adoption manifest](adoption-manifest.json). Azure resource definitions belong here;
reusable orchestration belongs in HoneyDrunk.Actions. There is no live apply workflow.

`terraform-roots.json` enumerates 19 independent roots, including the existing
estate, protected backend and seven proposed Identity/network/SQL roots. Reusable
modules remain available for future resources. Development names, regions and
legacy tags in adopted roots match the actual estate and are intentionally explicit.
Do not apply those roots against an empty state or another environment.

## Credential-free validation

Terraform 1.16.5 and AzureRM 5.9.0 are pinned. Directory coverage additionally uses
AzureAD 3.10.0, AzAPI 2.13.0 and Microsoft Graph 0.6.0. The shared checksum lock
covers Windows/Linux; the Actions validator stages an exact dependency subset for
each root. Every provider, including providers reached through local modules, must
be mocked. CI disables backend initialization and Azure authentication.

```powershell
python -m pip install -r <pinned-actions-checkout>/.github/config/terraform-requirements.txt
python <pinned-actions-checkout>/.github/scripts/terraform_validate.py .
python -m unittest discover -s tests -v
```

The required `Bicep Lint / Bicep Lint` compatibility status still requires Terraform
and secret checks to succeed. Its name does not restore Bicep. Provider mocks and
source checks are distinct from confidential live no-change-plan verification.
Never upload state, saved plans, backend metadata or authenticated logs to CI.

See [Identity initialization](nodes/identity/README.md) for the still-unexecuted
first-release contract and [migration history](docs/terraform-migration.md).
