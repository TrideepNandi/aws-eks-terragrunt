# DevOps role configuration for management cluster
locals {
  policies = {
    devops_admin = {
      name_suffix = "devops-admin-policy"
      description = "DevOps administrative permissions for management cluster"
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
              "ssm:*"
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
      description = "DevOps administrative role for management cluster"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${get_aws_account_id()}:root"
            }
            Condition = {
              StringEquals = {
                "sts:ExternalId" = "mgmt-devops-access"
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
        Cluster = "Management"
      }
    }
  }
}