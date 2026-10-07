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

  # Existing service accounts that may be impersonated through this pool.
  service_account_ids = var.gcp_service_account_ids

  sa_emails = {
    for id, sa in data.google_service_account.this : id => sa.email
  }

  sa_email_list = sort(values(local.sa_emails))

  has_single_service_account = length(local.service_account_ids) == 1

  # Preserved for the single-account output and the historical GitHub variable.
  sa_email = local.has_single_service_account ? local.sa_emails[local.service_account_ids[0]] : null

  # GCP_WIF_SA_<local-part>, with non-alphanumeric characters replaced by underscores.
  generated_service_account_email_variable_names = {
    for id in local.service_account_ids :
    id => "GCP_WIF_SA_${upper(replace(split("@", id)[0], "/[^A-Za-z0-9_]/", "_"))}"
  }

  # One account and no explicit map keeps the historical GitHub variable name and resource address.
  use_single_service_account_email_variable = local.has_single_service_account && length(var.github_gcp_wif_service_account_email_variable_names) == 0

  service_account_email_variable_names = local.use_single_service_account_email_variable ? {
    (local.service_account_ids[0]) = var.github_gcp_wif_service_account_email_variable_name
    } : {
    for id in local.service_account_ids :
    id => lookup(var.github_gcp_wif_service_account_email_variable_names, id, local.generated_service_account_email_variable_names[id])
  }

  unknown_service_account_variable_keys = sort(setsubtract(
    toset(keys(var.github_gcp_wif_service_account_email_variable_names)),
    toset(local.service_account_ids),
  ))

  reserved_github_variable_names = setunion(
    toset([
      upper(var.github_gcp_wif_project_id_variable_name),
      upper(var.github_gcp_wif_workload_identity_provider_variable_name),
      upper(var.github_gcp_wif_service_account_emails_variable_name),
    ]),
    toset([for name in keys(var.github_variables_additional) : upper(name)]),
  )

  invalid_service_account_variable_names = {
    for id, name in local.service_account_email_variable_names :
    id => name
    if !can(regex("^[A-Za-z_][A-Za-z0-9_]*$", name)) || startswith(upper(name), "GITHUB_") || (
      !local.use_single_service_account_email_variable && !contains(keys(var.github_gcp_wif_service_account_email_variable_names), id) && !can(regex("^GCP_WIF_SA_.+$", name))
    )
  }

  duplicate_service_account_variable_names = [
    for name in distinct([for variable_name in values(local.service_account_email_variable_names) : upper(variable_name)]) :
    name
    if length([for variable_name in values(local.service_account_email_variable_names) : variable_name if upper(variable_name) == name]) > 1
  ]

  conflicting_service_account_variable_names = [
    for variable_name in values(local.service_account_email_variable_names) : variable_name
    if contains(local.reserved_github_variable_names, upper(variable_name))
  ]

  core_github_variable_names = concat(
    [
      upper(var.github_gcp_wif_project_id_variable_name),
      upper(var.github_gcp_wif_workload_identity_provider_variable_name),
      upper(var.github_gcp_wif_service_account_emails_variable_name),
    ],
    local.use_single_service_account_email_variable ? [upper(var.github_gcp_wif_service_account_email_variable_name)] : [],
  )

  core_github_variable_names_are_unique = length(distinct(local.core_github_variable_names)) == length(local.core_github_variable_names)

  workload_identity_user_bindings = {
    for pair in setproduct(local.service_account_ids, keys(local.principal_sets)) :
    "${pair[0]}|${pair[1]}" => {
      service_account_id = data.google_service_account.this[pair[0]].name
      member             = local.principal_sets[pair[1]]
    }
  }

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
