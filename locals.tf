locals {
  resource_name_pool_suffix = "${random_id.suffix.hex}-${var.name}"

  repository_resource_suffix = "repository"

  # GitHub OIDC issuer URL
  github_issuer_url = var.github_token_issuer_url

  # Build attribute condition for repository access
  # GitHub uses "repository" claim in format "owner/repo"
  base_attribute_condition = "(${join(" || ", [for repo in var.github_repository_names : "attribute.repository_id==\"${data.github_repository.repositories[repo].repo_id}\""])})"

  # Add additional condition if provided
  attribute_condition = var.github_attribute_condition_additional != null ? "(${local.base_attribute_condition}) && (${var.github_attribute_condition_additional})" : local.base_attribute_condition

  # Principal subjects for IAM bindings
  principal_subjects = {
    for repo in var.github_repository_names :
    "${local.repository_resource_suffix}-${replace(repo, "/", "-")}" => "attribute.repository_id/${data.github_repository.repositories[repo].repo_id}"
  }

  principal_sets = {
    for key, subject in local.principal_subjects : key => "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/${subject}"
  }

  # Target service account email
  sa_email = data.google_service_account.this.email

  # Ensure the display_name is always 32 characters or less
  pool_display_name_suffix    = " Pool"
  pool_display_name_max_len   = 32 - length(local.pool_display_name_suffix)
  pool_display_name_truncated = substr(var.name, 0, local.pool_display_name_max_len)
  pool_display_name           = "${local.pool_display_name_truncated}${local.pool_display_name_suffix}"

  # Ensure the provider display_name is always 32 characters or less
  provider_display_name_suffix    = " Provider"
  provider_display_name_max_len   = 32 - length(local.provider_display_name_suffix)
  provider_display_name_truncated = substr(var.name, 0, local.provider_display_name_max_len)
  provider_display_name           = "${local.provider_display_name_truncated}${local.provider_display_name_suffix}"

  # Full workload identity provider path for google-github-actions/auth
  workload_identity_provider = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.this.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id}"

  # Parse repository names into owner and repo
  parsed_repositories = {
    for repo in var.github_repository_names :
    repo => {
      owner = split("/", repo)[0]
      name  = split("/", repo)[1]
      id    = data.github_repository.repositories[repo].repo_id
    }
  }
}
