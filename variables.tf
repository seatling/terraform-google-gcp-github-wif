variable "name" {
  description = "The name to use for all resources created by this module."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "name must be 1-63 chars, lowercase letters/numbers/hyphens, and must not start or end with a hyphen."
  }
}

# Google Cloud Platform (GCP) variables
variable "gcp_project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "gcp_service_account_ids" {
  description = "Account IDs, emails, or unique IDs of the target GCP service accounts that GitHub Actions may impersonate via this Workload Identity Federation configuration. Every configured repository can impersonate every listed service account."
  type        = list(string)

  validation {
    condition     = length(var.gcp_service_account_ids) > 0
    error_message = "At least one service account must be specified in gcp_service_account_ids."
  }

  validation {
    condition     = alltrue([for id in var.gcp_service_account_ids : trimspace(id) != "" && id == trimspace(id)])
    error_message = "gcp_service_account_ids must not contain empty identifiers or identifiers with leading or trailing spaces."
  }

  validation {
    condition     = length(distinct(var.gcp_service_account_ids)) == length(var.gcp_service_account_ids)
    error_message = "gcp_service_account_ids must not contain duplicates."
  }
}

variable "gcp_workload_identity_pool_provider_attribute_mapping" {
  description = "A map of attribute mappings for the GCP Workload Identity Federation provider. This allows you to customize how attributes are mapped from GitHub to GCP."
  type        = map(string)
  default = {
    # google.subject must be unique per token - using actor + run_id + run_attempt
    "google.subject"                  = "assertion.actor+\"::run:\"+assertion.run_id+\"::attempt:\"+assertion.run_attempt"
    "attribute.actor"                 = "assertion.actor"
    "attribute.actor_id"              = "assertion.actor_id"
    "attribute.repository"            = "assertion.repository"
    "attribute.repository_id"         = "assertion.repository_id"
    "attribute.repository_owner"      = "assertion.repository_owner"
    "attribute.repository_owner_id"   = "assertion.repository_owner_id"
    "attribute.repository_visibility" = "assertion.repository_visibility"
    "attribute.ref"                   = "assertion.ref"
    "attribute.ref_type"              = "assertion.ref_type"
    "attribute.event_name"            = "assertion.event_name"
    "attribute.workflow"              = "assertion.workflow"
    "attribute.workflow_ref"          = "assertion.workflow_ref"
    "attribute.job_workflow_ref"      = "assertion.job_workflow_ref"
    "attribute.environment"           = "assertion.environment"
    "attribute.runner_environment"    = "assertion.runner_environment"
  }

  validation {
    condition     = length(var.gcp_workload_identity_pool_provider_attribute_mapping) > 0 && contains(keys(var.gcp_workload_identity_pool_provider_attribute_mapping), "google.subject") && length(var.gcp_workload_identity_pool_provider_attribute_mapping["google.subject"]) > 0
    error_message = "gcp_workload_identity_pool_provider_attribute_mapping must contain a non-empty 'google.subject' mapping."
  }
}

# GitHub variables
variable "github_repository_names" {
  description = "The GitHub repository names (in format 'owner/repo') to allow access from."
  type        = list(string)

  validation {
    condition     = length(var.github_repository_names) > 0
    error_message = "At least one repository must be specified in github_repository_names."
  }

  validation {
    condition     = alltrue([for name in var.github_repository_names : can(regex("^[^/]+/[^/]+$", name))])
    error_message = "github_repository_names must be in the format 'owner/repo'."
  }

  validation {
    condition     = length(distinct(var.github_repository_names)) == length(var.github_repository_names)
    error_message = "github_repository_names must not contain duplicates."
  }

  validation {
    condition     = length(distinct([for repo in var.github_repository_names : split("/", repo)[0]])) == 1
    error_message = "All github_repository_names must belong to the same owner."
  }
}

variable "github_token_issuer_url" {
  description = "The URL of the GitHub OIDC token issuer."
  type        = string
  default     = "https://token.actions.githubusercontent.com"

  validation {
    condition     = var.github_token_issuer_url == "https://token.actions.githubusercontent.com"
    error_message = "github_token_issuer_url must be https://token.actions.githubusercontent.com. Enterprise issuers are no longer supported by this module."
  }
}

variable "github_gcp_wif_project_id_variable_name" {
  description = "The name of the GitHub Actions variable to store the GCP project ID for WIF."
  type        = string
  default     = "GCP_WIF_PROJECT_ID"
}

variable "github_gcp_wif_service_account_email_variable_name" {
  description = "The name of the GitHub Actions variable to store the GCP WIF service account email when exactly one service account is configured and github_gcp_wif_service_account_email_variable_names is empty."
  type        = string
  default     = "GCP_WIF_SERVICE_ACCOUNT_EMAIL"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.github_gcp_wif_service_account_email_variable_name)) && !startswith(upper(var.github_gcp_wif_service_account_email_variable_name), "GITHUB_")
    error_message = "github_gcp_wif_service_account_email_variable_name must be a valid GitHub Actions variable name and must not start with GITHUB_."
  }
}

variable "github_gcp_wif_service_account_emails_variable_name" {
  description = "The name of the GitHub Actions variable that stores a comma-separated list of service account emails allowed by this Workload Identity Federation configuration."
  type        = string
  default     = "GCP_WIF_SERVICE_ACCOUNT_EMAILS"

  validation {
    condition     = can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.github_gcp_wif_service_account_emails_variable_name)) && !startswith(upper(var.github_gcp_wif_service_account_emails_variable_name), "GITHUB_")
    error_message = "github_gcp_wif_service_account_emails_variable_name must be a valid GitHub Actions variable name and must not start with GITHUB_."
  }
}

variable "github_gcp_wif_service_account_email_variable_names" {
  description = "Optional map of service account identifier to GitHub Actions variable name. Keys must exactly match values in gcp_service_account_ids. Unlisted service accounts use GCP_WIF_SA_<ACCOUNT_ID> when more than one service account is configured. With one service account and an empty map, github_gcp_wif_service_account_email_variable_name is used instead."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for name in values(var.github_gcp_wif_service_account_email_variable_names) :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", name)) && !startswith(upper(name), "GITHUB_")
    ])
    error_message = "github_gcp_wif_service_account_email_variable_names values must be valid GitHub Actions variable names and must not start with GITHUB_."
  }

  validation {
    condition     = length(distinct([for name in values(var.github_gcp_wif_service_account_email_variable_names) : upper(name)])) == length(var.github_gcp_wif_service_account_email_variable_names)
    error_message = "github_gcp_wif_service_account_email_variable_names values must be unique. GitHub Actions variable names are case-insensitive."
  }
}

variable "github_gcp_wif_workload_identity_provider_variable_name" {
  description = "The name of the GitHub Actions variable to store the full workload identity provider path (used by google-github-actions/auth)."
  type        = string
  default     = "GCP_WORKLOAD_IDENTITY_PROVIDER"
}

variable "github_create_oidc_variables" {
  description = "Whether to create GitHub Actions variables for the WIF configuration. Set to false if you want to manage variables manually."
  type        = bool
  default     = true
}

variable "github_variables_additional" {
  description = "Additional GitHub Actions variables to create. This should be a map where the key is the variable name and the value is the variable value."
  type        = map(string)
  default     = {}
}

# Attribute condition customization
variable "github_attribute_condition_additional" {
  description = "Additional CEL expression to AND with the generated attribute condition. Use this to add extra restrictions like branch filters, environment filters, etc."
  type        = string
  default     = null

  validation {
    condition     = var.github_attribute_condition_additional == null || trimspace(var.github_attribute_condition_additional) != ""
    error_message = "github_attribute_condition_additional must be null or a non-empty CEL expression."
  }
}
