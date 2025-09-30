terraform {
  source = "../../modules/terraform/iam" # Fixed: was ../modules, should be ../../modules
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
}

# OPTION 1: Remove this dependency entirely
# dependency "eks_users" {
#   config_path = "../users"
# }

# OPTION 2: Or make it optional with skip_outputs
dependency "eks_users" {
  config_path = "../users"  # Fixed: removed get_terragrunt_dir(), use relative path
  
  skip_outputs = false  # We need the outputs
  
  # Allow planning without users being deployed yet
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    users = {
      "eks-developer" = {
        name = "eks-developer"
        arn  = "arn:aws:iam::123456789012:user/eks-developer"
      }
      "eks-devops" = {
        name = "eks-devops"
        arn  = "arn:aws:iam::123456789012:user/eks-devops"
      }
    }
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

  # Attach users created in users module
  user_policy_attachment = {
    eks-developer = dependency.eks_users.outputs.users["eks-developer"].arn  # Added .arn
    eks-devops    = dependency.eks_users.outputs.users["eks-devops"].arn     # Added .arn
  }
}