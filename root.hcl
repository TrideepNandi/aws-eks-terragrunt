# Root Terragrunt configuration
locals {
  # Parse the account configuration
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Get region from the directory path (if available)
  region_vars = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { locals = { aws_region = "us-east-1" } })

  # Extract values
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.account_id
  aws_region   = local.region_vars.locals.aws_region

  # Generate dynamic state key based on directory structure
  relative_path = path_relative_to_include()
  path_parts    = split("/", local.relative_path)

  # Safely check if we're in the special iam-roles case
  is_iam_roles_case = (
    length(local.path_parts) >= 2 && 
    try(local.path_parts[1], "") == "iam-roles"
  )

  # Create a clean state key based on the directory structure
  state_key = local.is_iam_roles_case ? (
    "${local.path_parts[0]}/app-cluster/iam/terraform.tfstate"
  ) : (
    local.relative_path != "" && local.relative_path != "." ? 
    "${local.relative_path}/terraform.tfstate" : 
    "terraform.tfstate"
  )
}

# Configure Terragrunt to automatically create the S3 bucket and DynamoDB table for remote state storage
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    # Single S3 bucket for all environments
    bucket = "terraform-state-${local.account_name}-${local.account_id}"

    # Dynamic state key based on directory structure
    key = local.state_key

    # Region where the S3 bucket should be created
    region = "us-east-1"

    # Enable encryption
    encrypt = true
  }
}

# Input variables that will be available to all child configurations
inputs = {
  account_name = local.account_name
  account_id   = local.account_id
  aws_region   = local.aws_region
}
