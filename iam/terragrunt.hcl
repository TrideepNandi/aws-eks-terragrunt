# Centralized IAM roles configuration for AWS
terraform {
  source = "../modules/terraform/iam-roles"
}

# Include the root configuration for shared settings
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Generate AWS provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-1"  # IAM is global, but we need to specify a region

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "production"
      Component   = "iam-roles"
    }
  }
}
EOF
}

# Include role definitions and common context
locals {
  # Read common context configuration
  context_vars = read_terragrunt_config(find_in_parent_folders("context.hcl"))
  
  # Common roles (shared across all clusters)
  devops_role    = read_terragrunt_config("${get_terragrunt_dir()}/roles/common/devops.hcl")
  developer_role = read_terragrunt_config("${get_terragrunt_dir()}/roles/common/developer.hcl")
}

# Input variables that will be available to the Terraform module
inputs = {
  name_prefix = "eks-global-"

  # Combine all policies from role files
  policies = merge(
    local.devops_role.locals.policies,
    local.developer_role.locals.policies
  )

  # Combine all roles from role files
  roles = merge(
    local.devops_role.locals.roles,
    local.developer_role.locals.roles
  )

  # OIDC providers (empty for now)
  oidc_providers = {}

  tags = merge(
    local.context_vars.locals.common_tags,
    {
      Purpose = "EKS-Global-IAM-Roles"
    }
  )
}