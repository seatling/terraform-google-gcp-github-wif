# Terraform Google GCP GitHub Workload Identity Federation Module

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
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name                   = "my-github-wif"
  gcp_project_id         = "my-gcp-project-id"
  gcp_service_account_id = "my-service-account@my-gcp-project-id.iam.gserviceaccount.com"

  github_repository_names = ["my-org/my-repo"]
}
```

### With Additional Security Conditions

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

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

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.5  |
| google    | >= 3.53 |
| random    | >= 3.0  |
| github    | >= 5.0  |

## Providers

| Name   | Version |
| ------ | ------- |
| google | >= 3.53 |
| random | >= 3.0  |
| github | >= 5.0  |

## Inputs

| Name                                                  | Description                                                                                               | Type           | Default                                         | Required |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | :------: |
| name                                                  | The name to use for all resources created by this module                                                  | `string`       | n/a                                             |   yes    |
| gcp_project_id                                        | The ID of the project in which to provision resources                                                     | `string`       | n/a                                             |   yes    |
| gcp_service_account_id                                | The account ID, email, or unique ID of the target GCP service account                                      | `string`       | n/a                                             |   yes    |
| github_repository_names                               | The GitHub repository names (in format 'owner/repo') to allow access from                                  | `list(string)` | n/a                                             |   yes    |
| gcp_workload_identity_pool_provider_attribute_mapping | A map of attribute mappings for the GCP Workload Identity Federation provider                             | `map(string)`  | See variables.tf                                |    no    |
| github_token_issuer_url                               | The URL of the GitHub OIDC token issuer                                                                   | `string`       | `"https://token.actions.githubusercontent.com"` |    no    |
| github_gcp_wif_project_id_variable_name               | The name of the GitHub Actions variable to store the GCP project ID for WIF                               | `string`       | `"GCP_WIF_PROJECT_ID"`                          |    no    |
| github_gcp_wif_service_account_email_variable_name      | The name of the GitHub Actions variable to store the GCP WIF service account email                        | `string`       | `"GCP_WIF_SERVICE_ACCOUNT_EMAIL"`               |    no    |
| github_gcp_wif_workload_identity_provider_variable_name | The name of the GitHub Actions variable to store the full workload identity provider path                  | `string`       | `"GCP_WORKLOAD_IDENTITY_PROVIDER"`              |    no    |
| github_create_oidc_variables                          | Whether to create GitHub Actions variables for the WIF configuration                                      | `bool`         | `true`                                          |    no    |
| github_variables_additional                           | Additional GitHub Actions variables to create                                                             | `map(string)`  | `{}`                                            |    no    |
| github_attribute_condition_additional                 | Additional CEL expression to AND with the generated attribute condition                                   | `string`       | `null`                                          |    no    |

## Outputs

| Name                               | Description                                                                                         |
| ---------------------------------- | --------------------------------------------------------------------------------------------------- |
| workload_identity_pool_name        | Full name of the Workload Identity Pool                                                             |
| workload_identity_pool_id          | ID of the Workload Identity Pool                                                                    |
| workload_identity_pool_provider_id | ID of the Workload Identity Provider                                                                |
| workload_identity_provider         | Full resource path for google-github-actions/auth                                                   |
| service_account_email              | Email of the Service Account                                                                        |
| principal_set                      | Principal sets for IAM bindings                                                                     |
| attribute_condition                | The attribute condition used                                                                        |
| github_actions_variables           | Map of GitHub Actions variables created                                                             |

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

# Combined conditions
github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\" && attribute.environment==\"production\""
```

## License

GPL v3
