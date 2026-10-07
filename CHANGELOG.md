# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0](https://github.com/seatling/terraform-google-gcp-github-wif/compare/v0.1.0...v0.2.0) (2026-10-07)


### Features

* support multiple service accounts per workflow identity ([8025e49](https://github.com/seatling/terraform-google-gcp-github-wif/commit/8025e4955f96074c315b248bd000fa059274d8bc))

## [Unreleased]

### Added

- Support multiple existing service accounts on one Workload Identity Federation configuration via `gcp_service_account_ids`.
- Publish each service account email as a GitHub Actions variable, plus a comma-separated `GCP_WIF_SERVICE_ACCOUNT_EMAILS` variable.

### Changed

- Replace `gcp_service_account_id` with required `gcp_service_account_ids`. One Workload Identity user binding is created for each service account and repository.

## 0.1.0 (2026-10-07)


### Features

* place random hex before name in pool and provider IDs to avoid collisions ([#13](https://github.com/seatling/terraform-google-gcp-github-wif/issues/13)) ([8a1e06f](https://github.com/seatling/terraform-google-gcp-github-wif/commit/8a1e06fa0e31b9a260b5466fe76f35361d99e1d0))
* remove useless variables ([4888683](https://github.com/seatling/terraform-google-gcp-github-wif/commit/4888683c87a8e248d81ae1fdad13fd4b8430157b))
* remove useless variables ([7387323](https://github.com/seatling/terraform-google-gcp-github-wif/commit/7387323f1012fd6311ea3d08e866d9d0b36acc07))
* use only github_repository_names and automatically fetch IDs to be used in federation conditions ([3e40224](https://github.com/seatling/terraform-google-gcp-github-wif/commit/3e40224a7af63d1816ca45467b41482f51d50813))
* use only github_repository_names and automatically fetch IDs to be used in federation conditions ([cad9885](https://github.com/seatling/terraform-google-gcp-github-wif/commit/cad9885310461d99b0330ae79fcb07532d4ba995))


### Bug Fixes

* add compare to changelog ([36597d8](https://github.com/seatling/terraform-google-gcp-github-wif/commit/36597d83c2914bf9565944d7b7336428bfdc399e))
* validation for github_organization_id now is null safe ([097558c](https://github.com/seatling/terraform-google-gcp-github-wif/commit/097558c18afc30ceb8999a69c3bdf80d16e2c93b))
* validation for github_organization_id now is null safe ([f0c166b](https://github.com/seatling/terraform-google-gcp-github-wif/commit/f0c166b8b5f375b96aa8ccaa437e8455af21fa14))

## [Unreleased]

## [1.0.0] - 2026-05-20

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.2.0...1.0.0)

### :warning: Breaking change

The workload identity pool and provider IDs now place the random hex suffix at the **beginning** of the identifier (e.g., `pool-a1b2c3d4-myname` instead of `pool-myname-a1b2c3d4`). This prevents the random part from being truncated when `var.name` is long, which could cause ID collisions.

**Upgrading will destroy and recreate the pool and provider resources.** These are pure configuration resources (identity federation settings), no data loss is involved. The service account itself is **not affected**, though its WIF IAM binding (`google_service_account_iam_member`) is recreated because it references the pool name.

See [UPGRADING.md](UPGRADING.md) for details.

### Changed

- Move random hex prefix before `var.name` in pool and provider IDs to avoid collisions caused by truncation.

## [0.2.0] - 2026-03-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.1.1...0.2.0)

- Remove `github_repository_ids` variable and all related logic.
- Fetch repository IDs dynamically using the GitHub provider based on the provided `github_repository_names`.
- Update the logic used in federation using repository names to reference the dynamically fetched repository IDs instead of relying on names directly.

## [0.1.1] - 2026-03-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.1.0...0.1.1)

- Fix a bug in the validation logic for `github_organization_id`. The issue was with how Terraform evaluates the `>` operator when the value is `null`, because in Terraform `null > 0` does not return `false`.

## [0.1.0] - 2026-03-02

- First release.
