---
applyTo: "**/*.tf"
---


# Terraform Instructions

## Module Structure
- Place all reusable logic in `modules/`.
- Each environment has its own folder under `environments/` with its own `main.tf`, `variables.tf`, `backend.tf`, etc.
- Reference modules in environment `main.tf` using relative paths.
- Never hardcode environment-specific values; use variables and `*.tfvars` files.

## State Management
- Always configure remote state in `backend.tf` per environment.
- Never share state files between environments.
- Use `terraform init` before planning or applying changes.

## Variables
- Define all required variables in `variables.tf` for each environment/module.
- Every variable must include a clear `description` and an explicit `type`.
- Add `validation` blocks for variables to enforce constraints (e.g., allowed values, string patterns, min/max).
- Use `my.tfvars` or similar for environment-specific overrides.
- Mark variables as `sensitive = true` when they contain secrets or credentials (e.g., passwords, API keys).
- Sensitive variables can also be declared as `ephemeral` if supported, to avoid storing them in state files.
- Example variable with validation and sensitivity:
	```hcl
	variable "region" {
		description = "The AWS region to deploy resources into."
		type        = string
		validation {
			condition     = contains(["eu-west-1", "eu-west-3"], var.region)
			error_message = "Region must be eu-west-1 or eu-west-3."
		}
	}

	variable "db_password" {
		description = "Database password."
		type        = string
		sensitive   = true
	}
	```

## Outputs
- All outputs must include a clear `description` explaining their purpose and usage.
- Mark outputs as `sensitive = true` when they contain secrets or credentials.
- Example output:
	```hcl
	output "bucket_arn" {
		description = "The ARN of the provisioned S3 bucket."
		value       = aws_s3_bucket.example.arn
	}

	output "db_password" {
		description = "Database password."
		value       = module.db.password
		sensitive   = true
	}
	```

## Code Style & Best Practices
- Use standard Terraform file names: `main.tf`, `variables.tf`, `backend.tf`, `provider.tf`, `versions.tf`.
- Prefer explicit resource names and outputs.
- Use comments to explain non-obvious logic or architectural decisions.
- Group related resources logically within modules.
- Avoid duplication; use modules and locals for reuse.
- Use `locals` for computed values and to avoid repetition in resource definitions. Example:
	```hcl
	locals {
		bucket_name = "${var.project}-${var.env}-bucket"
	}
	resource "aws_s3_bucket" "main" {
		bucket = local.bucket_name
		# ...
	}
	```
- Prefer `terraform_data` for provisioner-like or local actions; avoid `null_resource` unless absolutely necessary.

## Data Blocks
- When using `data` blocks, add `lifecycle` post conditions (such as `postcondition` blocks) to assert expected attributes and fail early if data is missing or invalid.
- Example:
	```hcl
	data "aws_iam_role" "example" {
		name = var.role_name

		lifecycle {
			postcondition {
				condition     = self.arn != ""
				error_message = "IAM role must exist and have a valid ARN."
			}
		}
	}
	```


