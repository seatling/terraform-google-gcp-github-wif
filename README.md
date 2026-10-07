# Terraform Google GCP GitHub Workload Identity Federation Module

> [!NOTE]  
  > This is a stripped-down fork of the original [terraform-google-gcp-github-wif](https://github.com/sparkfabrik/terraform-google-gcp-github-wif) module. We removed some features and simplified the configuration for easier usage and maintenance.

This Terraform module sets up **Google Cloud Platform (GCP) Workload Identity Federation (WIF)** to allow GitHub Actions workflows to authenticate with GCP without using static service account keys.

## Features

- Creates a Workload Identity Pool and OIDC Provider for GitHub Actions
- Restricts access to selected GitHub repositories using secure attribute conditions
- Binds Workload Identity users to an existing target GCP Service Account
- Automatically creates repository-level GitHub Actions variables with WIF configuration
- Flexible attribute conditions for fine-grained access control (e.g., branch, environment)

## Usage

### Basic Usage - Repository Level Access with Target Service Account

```hcl
module "github_wif" {
  source = "github.com/seatling/terraform-google-gcp-github-wif"

  name                   = "my-github-wif"
  gcp_project_id         = "my-gcp-project-id"
  gcp_service_account_id = "my-service-account@my-gcp-project-id.iam.gserviceaccount.com"

  github_repository_names = ["my-org/my-repo"]
}
```

### With Additional Security Conditions

```hcl
module "github_wif" {
  source = "github.com/seatling/terraform-google-gcp-github-wif"

  name                   = "prod-deploy"
  gcp_project_id         = "my-gcp-project-id"
  gcp_service_account_id = "my-service-account@my-gcp-project-id.iam.gserviceaccount.com"

  github_repository_names = ["my-org/my-repo"]

  # Only allow from main branch and production environment
  github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\" && attribute.environment==\"production\""
}
```

## GitHub Actions Workflow

After applying this module, use the following workflow configuration:

```yaml
name: Deploy to GCP

on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write # Required for OIDC authentication

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - id: auth
        name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_WIF_SERVICE_ACCOUNT_EMAIL }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Use gcloud CLI
        run: gcloud services list
```

## GitHub OIDC Token Claims

This module maps the following GitHub OIDC token claims to GCP attributes:

| GitHub Claim            | GCP Attribute                     | Description                              |
| ----------------------- | --------------------------------- | ---------------------------------------- |
| `repository`            | `attribute.repository`            | Full repository name (owner/repo)        |
| `repository_id`         | `attribute.repository_id`         | Numeric repository ID                    |
| `repository_owner`      | `attribute.repository_owner`      | Organization or user name                |
| `repository_owner_id`   | `attribute.repository_owner_id`   | Numeric owner ID                         |
| `repository_visibility` | `attribute.repository_visibility` | public, private, or internal             |
| `actor`                 | `attribute.actor`                 | User who triggered the workflow          |
| `actor_id`              | `attribute.actor_id`              | Numeric user ID                          |
| `ref`                   | `attribute.ref`                   | Git ref (e.g., refs/heads/main)          |
| `ref_type`              | `attribute.ref_type`              | branch or tag                            |
| `event_name`            | `attribute.event_name`            | Trigger event (push, pull_request, etc.) |
| `workflow`              | `attribute.workflow`              | Workflow name                            |
| `workflow_ref`          | `attribute.workflow_ref`          | Full workflow path with ref              |
| `job_workflow_ref`      | `attribute.job_workflow_ref`      | Reusable workflow reference              |
| `environment`           | `attribute.environment`           | Deployment environment name              |
| `runner_environment`    | `attribute.runner_environment`    | github-hosted or self-hosted             |

  ## Validation and Guardrails

- Repository mode constraints:
  - At least one repository must be specified in `github_repository_names`.
  - `github_repository_names` must be in the format `owner/repo`.
  - `github_repository_names` must be unique.
  - All repositories must belong to the same owner.
- Issuer constraint:
  - `github_token_issuer_url` must remain `https://token.actions.githubusercontent.com`.

## Security Considerations

1. **Principle of Least Privilege**: Use repository-level access instead of organization-level when possible
2. **Branch Protection**: Add branch conditions to limit access to protected branches
3. **Environment Protection**: Use GitHub environments with protection rules
4. **Attribute Conditions**: Use `github_attribute_condition_additional` to add extra restrictions

## Example Attribute Conditions

```hcl
# Only main branch
github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\""

# Only production environment
github_attribute_condition_additional = "attribute.environment==\"production\""

# Only github-hosted runners
github_attribute_condition_additional = "attribute.runner_environment==\"github-hosted\""
```

## Combined conditions
```hcl
github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\" && attribute.environment==\"production\""
```


## License

GPL v3
