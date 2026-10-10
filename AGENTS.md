# HoneyDrunk.Infrastructure agent instructions

Own Azure resource definitions; reusable CI/deploy orchestration belongs in HoneyDrunk.Actions. Start with [README.md](README.md), the affected module/node README and [.github/workflows/pr.yml](.github/workflows/pr.yml).

Terraform is the selected IaC direction as of October 10, 2026. Migration implementation has started in a separate workstream; nothing has been applied or deployed by that workstream. Current main remains Bicep and its validation is still required. Preserve existing Bicep and plan adoption/import before replacing stateful resources. Preserve the selected App Service, VNet and shared SQL hosting intent; unmerged hosting PRs are proposals, not deployed state. Do not provision resources, apply plans or change credentials/permissions from an instruction-maintenance task.

Read the [shared engineering conventions](https://github.com/HoneyDrunkStudios/HoneyDrunk.Standards/blob/main/HoneyDrunk.Standards/docs/CONVENTIONS.md) and this repository's owning documentation before editing. Apply the parts relevant to this stack; preserve existing public contracts, dependency direction and repository-specific behavior. Verify shared capabilities in current code before reusing them; a catalog entry or scaffold is not an implemented integration.

Work within the selected request. Preserve unrelated changes and use a separate worktree when needed. Review the final diff, use Conventional Commits and ready-for-review PRs with exactly one accurate `Authorship:` line and a `Request:` line; include the authorship in commit trailers. Run meaningful checks for the affected behavior and report the reviewed/tested revision, failures and unrun checks. For documentation-only changes, check links, paths and instruction consistency. Preserve required checks and inspect actual latest-head Sonar new-code findings where analysis applies; do not suppress findings or weaken gates to obtain a pass. Legacy Grid Review is retired; do not restore its workers, queues or bypass labels. A configured replacement reviewer is not evidence of a completed review or enforcing merge check.

## Verification

For IaC changes, use the pinned Bicep/Azure CLI versions and offline contract tests documented in [Pulse offline verification](nodes/pulse/README.md#offline-verification); CI runs `python -m unittest discover -s tests -v` plus Bicep lint and secret scanning. Do not substitute a Terraform command for the current Bicep checks. Keep live plan/apply evidence separate from offline checks.
