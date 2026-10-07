# GitHub Actions variables for Workload Identity Federation
# Repository-level variables for each specified repository

# Create WIF variables at repository level
resource "github_actions_variable" "gcp_wif_project_id" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_project_id_variable_name
  value         = data.google_project.project.project_id
}

resource "github_actions_variable" "gcp_wif_service_account_email" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_service_account_email_variable_name
  value         = local.sa_email
}

resource "github_actions_variable" "gcp_workload_identity_provider" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_workload_identity_provider_variable_name
  value         = local.workload_identity_provider
}

# Additional variables
resource "github_actions_variable" "additional" {
  for_each = var.github_create_oidc_variables ? {
    for item in flatten([
      for repo in var.github_repository_names : [
        for key, value in var.github_variables_additional : {
          key   = "${local.parsed_repositories[repo].name}--${key}"
          repo  = local.parsed_repositories[repo].name
          name  = key
          value = value
        }
      ]
    ]) : item.key => item
  } : {}

  repository    = each.value.repo
  variable_name = each.value.name
  value         = each.value.value
}
