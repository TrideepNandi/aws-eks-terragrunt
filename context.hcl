# Common context configuration for all modules
locals {
  # Common project information
  group_name       = "infra"
  project_name     = "eks-multi-region"
  project_code     = "eks-mr"
  environment_name = "production"
  
  # Common tags applied to all resources
  common_tags = {
    ManagedBy   = "Terragrunt"
    Environment = "production"
    Project     = "eks-multi-region"
  }
}