# terragrunt.hcl for s3-backend

terraform {
  source = "../modules/terraform/s3-backend"
}

# Use local backend for S3 backend creation (chicken-and-egg problem)
remote_state {
  backend = "local"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

# Read account, region, and context configuration from files
locals {
  # Parse the account configuration
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  
  # Parse region configuration (default to us-east-1 if not found)
  region_vars = try(read_terragrunt_config(find_in_parent_folders("region.hcl")), { 
    locals = { 
      aws_region = "us-east-1"
      aws_region_short = "use1"
    } 
  })
  
  # Parse common context configuration
  context_vars = read_terragrunt_config(find_in_parent_folders("context.hcl"))
  
  # Extract values
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.account_id
  aws_region   = local.region_vars.locals.aws_region
  aws_region_short = local.region_vars.locals.aws_region_short
}

# Generate AWS provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "production"
      Component   = "s3-backend"
    }
  }
}
EOF
}

# Input variables passed to the Terraform module
inputs = {
  context = {
    # Use account information from configuration files
    aws_account_name = local.account_name
    aws_account_id   = local.account_id
    aws_region       = local.aws_region
    aws_region_short = local.aws_region_short
    
    # Use common context from context.hcl
    group_name       = local.context_vars.locals.group_name
    project_name     = local.context_vars.locals.project_name
    project_code     = local.context_vars.locals.project_code
    environment_name = local.context_vars.locals.environment_name

    # S3 backend specific values
    workload_name  = "backend"
    instance_index = 1
    tags = merge(
      local.context_vars.locals.common_tags,
      {
        Purpose = "terraform-state-backend"
      }
    )
  }
}
