include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/terraform/networking"
}

# Read common context and region configuration
locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  context_vars = read_terragrunt_config(find_in_parent_folders("context.hcl"))
  aws_region = local.region_vars.locals.aws_region
  
  # Read VPC and Security Groups configurations
  vpc_config = read_terragrunt_config("${get_terragrunt_dir()}/vpc.hcl")
  security_groups_config = read_terragrunt_config("${get_terragrunt_dir()}/security-groups.hcl")
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
      version = ">= 5.95.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "production"
      Component   = "networking"
      Region      = "${local.aws_region}"
    }
  }
}
EOF
}

dependency "s3_backend" {
  config_path = "../../../s3-backend"
}

inputs = {
  context = {
    aws_region       = local.aws_region
    aws_region_short = local.region_vars.locals.aws_region_short
    group_name       = local.context_vars.locals.group_name
    project_name     = local.context_vars.locals.project_name
    project_code     = local.context_vars.locals.project_code
    environment_name = local.context_vars.locals.environment_name
    workload_name    = "app"
    instance_index   = 3
    tags             = local.context_vars.locals.common_tags
  }

  # VPC configuration from vpc.hcl
  vpc = local.vpc_config.locals.vpc_config

  # Security Groups configuration from security-groups.hcl
  security_groups = local.security_groups_config.locals.security_groups_config
}