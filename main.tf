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
  account_id = var.gcp_service_account_id
  project    = var.gcp_project_id
}

resource "google_service_account_iam_member" "this" {
  for_each = local.principal_sets

  service_account_id = data.google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value
}
