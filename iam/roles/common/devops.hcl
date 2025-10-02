locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id

  policies = {
    devops_full_eks = {
      name_suffix = "devops-full-eks"
      description = "Full admin access to EKS"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = "*"
            Resource = "*"
          }
        ]
      })
    }
  }

  roles = {
    devops = {
      name_suffix  = "devops-role"
      description  = "DevOps full EKS role"

      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${local.account_id}:user/eks-devops"
            }
            Action    = "sts:AssumeRole"
          }
        ]
      })

      custom_policy_attachments = ["devops_full_eks"]
      managed_policy_arns       = ["arn:aws:iam::aws:policy/AdministratorAccess"]

      tags = {
        Role   = "DevOps"
        Scope  = "EKS"
        Access = "Full"
      }
    }
  }
}
