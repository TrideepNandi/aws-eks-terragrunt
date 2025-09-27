include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/terraform/iam-roles"
}

# Read region configuration
locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region = local.region_vars.locals.aws_region
}

# Generate AWS provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14.1"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"  # IAM is global, but we need to specify a region

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "production"
      Component   = "iam-roles"
      Region      = "${local.aws_region}"
      Cluster     = "management"
    }
  }
}
EOF
}

# Include role definitions and common context
locals {
  # Read common context and region configuration
  context_vars = read_terragrunt_config(find_in_parent_folders("context.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Role definitions
  devops_role    = read_terragrunt_config("${get_terragrunt_dir()}/roles/devops.hcl")
  developer_role = read_terragrunt_config("${get_terragrunt_dir()}/roles/developer.hcl")

  # Extract values
  aws_region = local.region_vars.locals.aws_region
  region_short = local.region_vars.locals.aws_region_short
}

inputs = {
  name_prefix = "mgmt-${local.region_short}-"

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

  tags = merge(
    local.context_vars.locals.common_tags,
    {
      Region = local.aws_region
      Purpose = "Management-Cluster-IAM"
      Cluster = "management"
    }
  )
}