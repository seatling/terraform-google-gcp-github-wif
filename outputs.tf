# Google Workload Identity Federation outputs
output "workload_identity_pool_name" {
  description = "The full name of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.this.name
}

output "workload_identity_pool_id" {
  description = "The ID of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.this.workload_identity_pool_id
}

output "workload_identity_pool_provider_id" {
  description = "The ID of the Workload Identity Provider."
  value       = google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id
}

output "workload_identity_provider" {
  description = "The full resource path of the Workload Identity Provider (for use with google-github-actions/auth)."
  value       = local.workload_identity_provider
}

output "service_account_email" {
  description = "The email of the service account when exactly one is configured. Null when multiple service accounts are configured; use service_account_emails instead."
  value       = local.sa_email
}

output "service_account_emails" {
  description = "Map of configured service account identifier to the service account email."
  value       = local.sa_emails
}

output "principal_set" {
  description = "The principal sets string used for IAM bindings."
  value       = local.principal_sets
}

output "attribute_condition" {
  description = "The attribute condition used for the Workload Identity Provider."
  value       = local.attribute_condition
}

# GitHub Actions variables outputs
output "github_actions_variables" {
  description = "The GitHub Actions variables created by this module."
  value = merge(
    {
      (var.github_gcp_wif_project_id_variable_name)                 = data.google_project.project.project_id
      (var.github_gcp_wif_workload_identity_provider_variable_name) = local.workload_identity_provider
      (var.github_gcp_wif_service_account_emails_variable_name)     = join(",", local.sa_email_list)
    },
    {
      for id, variable_name in local.service_account_email_variable_names :
      variable_name => local.sa_emails[id]
    }
  )
}
