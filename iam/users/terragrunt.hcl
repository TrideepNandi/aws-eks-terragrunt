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
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id
  eks_users    = read_terragrunt_config("${get_terragrunt_dir()}/eks-users.hcl")
}

# Users are created AFTER roles (but don't need role outputs)
dependency "roles" {
  config_path  = "../roles"
  skip_outputs = true  # We only need roles to exist, not their outputs
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {}
}

inputs = {
  name_prefix = "eks-"
  users       = local.eks_users.locals.users
}