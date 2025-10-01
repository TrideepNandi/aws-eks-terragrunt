terraform {
  source = "../../modules/terraform/iam"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}

locals {
  devops_role    = read_terragrunt_config("${get_terragrunt_dir()}/common/devops.hcl")
  developer_role = read_terragrunt_config("${get_terragrunt_dir()}/common/developer.hcl")
  
  # Get account ID for constructing user ARNs
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id
}

# Add dependency back for Terramate to detect, but skip outputs to avoid circular dependency
dependency "eks_users" {
  config_path  = "../users"
  skip_outputs = true  # Don't read outputs, just ensure users are created first
  
  # Mock outputs for planning
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    eks_admin_role_arn  = "arn:aws:iam::123456789012:role/eks-admin"
    eks_worker_role_arn = "arn:aws:iam::123456789012:role/eks-worker"
  }
}

inputs = {
  name_prefix = "eks-global-"

  policies = merge(
    local.devops_role.locals.policies,
    local.developer_role.locals.policies
  )

  roles = merge(
    local.devops_role.locals.roles,
    local.developer_role.locals.roles
  )

  # Construct user ARNs directly instead of using dependency outputs
  user_policy_attachment = {
    eks-developer = "arn:aws:iam::${local.account_id}:user/eks-developer"
    eks-devops    = "arn:aws:iam::${local.account_id}:user/eks-devops"
  }
}
