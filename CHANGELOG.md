# Changelog

All notable changes to the HoneyDrunk.Infrastructure Bicep-content surface are
recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Repo scaffold (ADR-0077 packet 11): `modules/` (seven per-concern subdirectories
  with READMEs), `platform/`, and `nodes/` tree; single root `bicepconfig.json`
  carrying the ADR-0077 D3 naming/tagging + secret-hygiene linter rules across all
  three subtrees; repo `README.md` and this `CHANGELOG.md`; `.honeydrunk-review.yaml`
  (`enabled: true`); `.github/workflows/pr.yml` consuming the
  `HoneyDrunk.Actions` `job-bicep-lint.yml` gate (the Bicep-native `core` check)
  plus `job-secret-scan.yml`; and `.github/workflows/pr-review.yml` (the ADR-0086
  Grid review trigger). Module references are local relative path — no registry,
  no `br:` references.
