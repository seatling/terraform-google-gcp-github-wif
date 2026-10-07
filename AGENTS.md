# AGENTS.md

Guidance for AI coding agents working in this repository.

## Scope

- Reusable Terraform module providing Google Cloud Platform (GCP) Workload Identity Federation (WIF) for GitHub Actions.
- Allows GitHub Actions workflows in specified repositories to authenticate against GCP using OIDC without static service account keys.
- Binds Workload Identity users to one or more existing target GCP service accounts (`roles/iam.workloadIdentityUser`). Every configured repository can impersonate every configured service account.
- Automatically manages repository-level GitHub Actions variables for WIF configuration.
- Scope is strictly repository-level federation for repositories under a single owner; organization-level and GitHub Enterprise federations are intentionally unsupported.

## Architecture Map

- [main.tf](main.tf): Core resources including [random_id](main.tf#L1) suffix, GCP Workload Identity Pool ([google_iam_workload_identity_pool](main.tf#L10)), OIDC Provider ([google_iam_workload_identity_pool_provider](main.tf#L17)), service account lookups, and IAM member bindings ([google_service_account_iam_member](main.tf#L80)).
- [variables.tf](variables.tf): Module inputs with strict type definitions and validation blocks (naming constraints, single-owner verification, format checks).
- [locals.tf](locals.tf): Resource naming suffixing, display name truncation (max 32 characters), CEL attribute condition composition, and `principalSet` mapping.
- [github.tf](github.tf): Provisioning of repository-level GitHub Actions variables ([github_actions_variable](github.tf#L5)) for project ID, service account emails, and workload identity provider path.
- [data.tf](data.tf): Dynamic GitHub repository lookups ([data.github_repository](data.tf#L1)) to retrieve immutable numeric repository IDs.
- [outputs.tf](outputs.tf): Exported attributes including pool and provider names/IDs, full provider resource path, service account email, and variables map.
- [versions.tf](versions.tf): Minimum Terraform version (`>= 1.5`) and required provider constraints (`google`, `random`, `github`).

## Build, Lint, and Validation

Run validation commands from the repository root:

1. Format check: `terraform fmt -check`
2. Linting: `tflint --init && tflint -f compact`
3. Static security scan: `docker run -t -v ${PWD}:/tf --workdir /tf bridgecrew/checkov --directory /tf --skip-check CKV_TF_1 --quiet --compact` (mirrors [.github/workflows/lints.yml](.github/workflows/lints.yml))

Before finishing any Terraform changes, run `terraform fmt` and ensure `tflint` produces no warnings or errors.

## Repo-Specific Conventions & Pitfalls

- **Repository-Level Scope Only**: Do not reintroduce organization-level access, organization variables, or GitHub Enterprise issuer logic. The module is intentionally restricted to repository-level federation.
- **Repository ID Lookup via GitHub Provider**: Repositories are provided by `owner/repo` string in `var.github_repository_names`, but mapped internally to numeric repository IDs via [data.tf](data.tf#L1). Attribute conditions and `principalSet` bindings must always use `attribute.repository_id` rather than repository names to prevent namespace hijacking.
- **Single Owner Constraint**: `var.github_repository_names` enforces that all repositories share the same GitHub owner.
- **Pool and Provider ID Randomization**: Pool and provider resource IDs prefix the random hex before the name (`pool-${random_id.suffix.hex}-${var.name}`), truncated to 32 characters. This ensures the random suffix is never truncated when `var.name` is long, preventing collision issues.
- **Display Name Length Limits**: GCP imposes a 32-character maximum on Workload Identity Pool and Provider display names. Suffixes ` Pool` and ` Provider` require truncating `var.name` via [locals.tf](locals.tf#L29-L39).
- **Target Service Accounts**: Target service accounts must already exist in `gcp_project_id`; the module looks them up via `data.google_service_account` and does not provision them. Pass them in `gcp_service_account_ids`. All configured repositories can impersonate all configured service accounts because they share one attribute condition.
- **Security Checkov Suppressions**: `CKV_GCP_125` is intentionally skipped on [google_iam_workload_identity_pool_provider.this](main.tf#L17) because access is restricted via CEL repository ID attribute conditions.
- **Releases & Commits**: Follow Conventional Commits (`feat:`, `fix:`, `chore:`, etc.) for automated releases via Release Please ([.github/workflows/release.yml](.github/workflows/release.yml)).

## References

- Module usage and examples: [README.md](README.md)
- Release history and migration notes: [CHANGELOG.md](CHANGELOG.md)
- Terraform coding standards: [.github/instructions/tf.instructions.md](.github/instructions/tf.instructions.md)
- CI linting workflow: [.github/workflows/lints.yml](.github/workflows/lints.yml)
- Release Please configuration: [.github/workflows/release.yml](.github/workflows/release.yml)

