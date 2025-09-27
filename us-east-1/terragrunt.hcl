# Regional Terragrunt configuration for US-East-1
# This allows running terragrunt commands at the regional level

# Include the root configuration for shared settings
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Regional-specific configuration
locals {
  region_vars = read_terragrunt_config("${get_terragrunt_dir()}/region.hcl")
  aws_region = local.region_vars.locals.aws_region
  region_short = local.region_vars.locals.aws_region_short
}

# Override inputs that are common to all components in this region
inputs = {
  aws_region = local.aws_region
  region_short = local.region_short

  # Common tags for all resources in this region
  common_tags = {
    Region = local.aws_region
    ManagedBy = "Terragrunt"
    Environment = "production"
  }
}