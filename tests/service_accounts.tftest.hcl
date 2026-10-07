mock_provider "google" {}
mock_provider "github" {}
mock_provider "random" {}

variables {
  name                    = "my-github-wif"
  gcp_project_id          = "my-gcp-project-id"
  github_repository_names = ["my-org/my-repo"]
}

run "single_service_account" {
  command = plan

  variables {
    gcp_service_account_ids = ["deployer@my-gcp-project-id.iam.gserviceaccount.com"]
  }

  override_data {
    target = data.google_project.project
    values = {
      project_id = "my-gcp-project-id"
      number     = "123456789"
    }
  }

  override_data {
    target = data.github_repository.repositories["my-org/my-repo"]
    values = {
      repo_id = "999"
      name    = "my-repo"
    }
  }

  override_data {
    target = data.google_service_account.this["deployer@my-gcp-project-id.iam.gserviceaccount.com"]
    values = {
      email = "deployer@my-gcp-project-id.iam.gserviceaccount.com"
      name  = "projects/my-gcp-project-id/serviceAccounts/deployer@my-gcp-project-id.iam.gserviceaccount.com"
    }
  }

  assert {
    condition     = output.service_account_email == "deployer@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "A single service account must still be exposed by service_account_email."
  }

  assert {
    condition     = length(google_service_account_iam_member.this) == 1
    error_message = "A single service account must receive one Workload Identity user binding per repository."
  }

  assert {
    condition     = output.github_actions_variables["GCP_WIF_SERVICE_ACCOUNT_EMAIL"] == "deployer@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "A single service account must keep GCP_WIF_SERVICE_ACCOUNT_EMAIL."
  }
}

run "multiple_service_accounts_share_one_pool" {
  command = plan

  variables {
    gcp_service_account_ids = [
      "deployer@my-gcp-project-id.iam.gserviceaccount.com",
      "reader@my-gcp-project-id.iam.gserviceaccount.com",
    ]
    github_gcp_wif_service_account_email_variable_names = {
      "deployer@my-gcp-project-id.iam.gserviceaccount.com" = "GCP_WIF_DEPLOYER_SERVICE_ACCOUNT_EMAIL"
      "reader@my-gcp-project-id.iam.gserviceaccount.com"   = "GCP_WIF_READER_SERVICE_ACCOUNT_EMAIL"
    }
  }

  override_data {
    target = data.google_project.project
    values = {
      project_id = "my-gcp-project-id"
      number     = "123456789"
    }
  }

  override_data {
    target = data.github_repository.repositories["my-org/my-repo"]
    values = {
      repo_id = "999"
      name    = "my-repo"
    }
  }

  override_data {
    target = data.google_service_account.this["deployer@my-gcp-project-id.iam.gserviceaccount.com"]
    values = {
      email = "deployer@my-gcp-project-id.iam.gserviceaccount.com"
      name  = "projects/my-gcp-project-id/serviceAccounts/deployer@my-gcp-project-id.iam.gserviceaccount.com"
    }
  }

  override_data {
    target = data.google_service_account.this["reader@my-gcp-project-id.iam.gserviceaccount.com"]
    values = {
      email = "reader@my-gcp-project-id.iam.gserviceaccount.com"
      name  = "projects/my-gcp-project-id/serviceAccounts/reader@my-gcp-project-id.iam.gserviceaccount.com"
    }
  }

  assert {
    condition     = output.service_account_email == null
    error_message = "service_account_email must be null when multiple service accounts are configured."
  }

  assert {
    condition = output.service_account_emails == {
      "deployer@my-gcp-project-id.iam.gserviceaccount.com" = "deployer@my-gcp-project-id.iam.gserviceaccount.com"
      "reader@my-gcp-project-id.iam.gserviceaccount.com"   = "reader@my-gcp-project-id.iam.gserviceaccount.com"
    }
    error_message = "Both service account emails must be exported."
  }

  assert {
    condition     = length(google_service_account_iam_member.this) == 2
    error_message = "Each service account must receive a Workload Identity user binding."
  }

  assert {
    condition     = output.github_actions_variables["GCP_WIF_SERVICE_ACCOUNT_EMAILS"] == "deployer@my-gcp-project-id.iam.gserviceaccount.com,reader@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "The emails variable must list both service accounts in sorted order."
  }

  assert {
    condition     = output.github_actions_variables["GCP_WIF_DEPLOYER_SERVICE_ACCOUNT_EMAIL"] == "deployer@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "The deployer variable must use the configured name."
  }
}

run "multiple_service_accounts_use_generated_variable_names" {
  command = plan

  variables {
    gcp_service_account_ids = [
      "deployer",
      "reader",
    ]
  }

  override_data {
    target = data.google_project.project
    values = {
      project_id = "my-gcp-project-id"
      number     = "123456789"
    }
  }

  override_data {
    target = data.github_repository.repositories["my-org/my-repo"]
    values = {
      repo_id = "999"
      name    = "my-repo"
    }
  }

  override_data {
    target = data.google_service_account.this["deployer"]
    values = {
      email = "deployer@my-gcp-project-id.iam.gserviceaccount.com"
      name  = "projects/my-gcp-project-id/serviceAccounts/deployer@my-gcp-project-id.iam.gserviceaccount.com"
    }
  }

  override_data {
    target = data.google_service_account.this["reader"]
    values = {
      email = "reader@my-gcp-project-id.iam.gserviceaccount.com"
      name  = "projects/my-gcp-project-id/serviceAccounts/reader@my-gcp-project-id.iam.gserviceaccount.com"
    }
  }

  assert {
    condition     = output.github_actions_variables["GCP_WIF_SA_DEPLOYER"] == "deployer@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "Omitted service account variable names must be generated from the account id."
  }

  assert {
    condition     = output.github_actions_variables["GCP_WIF_SA_READER"] == "reader@my-gcp-project-id.iam.gserviceaccount.com"
    error_message = "Each service account must get its own generated variable name."
  }
}


