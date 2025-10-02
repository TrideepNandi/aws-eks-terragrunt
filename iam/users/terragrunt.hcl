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
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id
  eks_users    = read_terragrunt_config("${get_terragrunt_dir()}/eks-users.hcl")
}

# NO dependency block here - users don't need roles to be created

inputs = {
  name_prefix = "eks-"
  account_id  = local.account_id
  users       = local.eks_users.locals.users
}
