resource "random_id" "suffix" {
  byte_length = 4
}

# Google resources for Workload Identity Federation
data "google_project" "project" {
  project_id = var.gcp_project_id
}

resource "google_iam_workload_identity_pool" "this" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = "pool-${substr(local.resource_name_pool_suffix, 0, 32 - length("pool-"))}"
  display_name              = local.pool_display_name
  description               = "Identity pool for ${var.name}"
}

resource "google_iam_workload_identity_pool_provider" "this" {
  #checkov:skip=CKV_GCP_125:Access is restricted via attribute.repository_id attribute condition
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "provider-${substr(local.resource_name_pool_suffix, 0, 32 - length("provider-"))}"
  display_name                       = local.provider_display_name
  description                        = "OIDC identity pool provider for ${var.name}"
  attribute_condition                = local.attribute_condition
  attribute_mapping                  = var.gcp_workload_identity_pool_provider_attribute_mapping

  oidc {
    issuer_uri = local.github_issuer_url
  }
}

data "google_service_account" "this" {
  for_each = toset(local.service_account_ids)

  account_id = each.value
  project    = var.gcp_project_id

  lifecycle {
    postcondition {
      condition     = self.email != "" && self.name != ""
      error_message = "Service account ${each.key} must already exist in project ${var.gcp_project_id} and expose an email and resource name."
    }
  }
}

# Fail before creating federation resources when the service account list or
# GitHub variable names are ambiguous. Variable validation cannot reference other variables.
resource "terraform_data" "service_account_guards" {
  input = local.service_account_ids

  lifecycle {
    precondition {
      condition     = length(distinct([for sa in data.google_service_account.this : sa.email])) == length(data.google_service_account.this)
      error_message = "gcp_service_account_ids must resolve to distinct service accounts."
    }

    precondition {
      condition     = length(local.unknown_service_account_variable_keys) == 0
      error_message = "github_gcp_wif_service_account_email_variable_names keys must match configured service account identifiers: ${join(", ", local.unknown_service_account_variable_keys)}."
    }

    precondition {
      condition     = length(local.invalid_service_account_variable_names) == 0
      error_message = "Could not derive a valid GitHub Actions variable name for: ${join(", ", keys(local.invalid_service_account_variable_names))}. Set github_gcp_wif_service_account_email_variable_names for those identifiers."
    }

    precondition {
      condition     = length(local.duplicate_service_account_variable_names) == 0
      error_message = "Service account GitHub Actions variable names must be unique (names are case-insensitive): ${join(", ", local.duplicate_service_account_variable_names)}."
    }

    precondition {
      condition     = length(local.conflicting_service_account_variable_names) == 0 && local.core_github_variable_names_are_unique
      error_message = "Service account GitHub Actions variable names collide with project, provider, emails-list, or additional variable names: ${join(", ", local.conflicting_service_account_variable_names)}."
    }
  }
}

resource "google_service_account_iam_member" "this" {
  for_each = local.workload_identity_user_bindings

  service_account_id = each.value.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.member

  depends_on = [terraform_data.service_account_guards]
}
