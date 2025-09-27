# DevOps role configuration - Global administrative access
locals {
  # Get account information from account.hcl
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id = local.account_vars.locals.account_id
  policies = {
    devops_admin = {
      name_suffix = "devops-admin-policy"
      description = "DevOps administrative permissions for EKS and AWS services"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "iam:*",
              "ec2:*",
              "vpc:*",
              "s3:*",
              "cloudwatch:*",
              "logs:*",
              "eks:*",
              "ecr:*",
              "route53:*",
              "acm:*"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  roles = {
    devops = {
      name_suffix = "devops-role"
      description = "DevOps administrative role for global EKS cluster management"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${local.account_id}:root"
            }
            Condition = {
              StringEquals = {
                "sts:ExternalId" = "devops-access"
              }
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      custom_policy_attachments = ["devops_admin"]
      tags = {
        Role = "DevOps"
        Access = "Administrative"
        Scope = "Global"
      }
    }
  }
}