# Developer role configuration - Read-only access for debugging
locals {
  # Get account information from account.hcl
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id = local.account_vars.locals.account_id
  policies = {
    developer_readonly = {
      name_suffix = "developer-readonly-policy"
      description = "Developer read-only access to logs and basic resources"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "logs:DescribeLogGroups",
              "logs:DescribeLogStreams",
              "logs:GetLogEvents",
              "logs:FilterLogEvents",
              "cloudwatch:GetMetricStatistics",
              "cloudwatch:ListMetrics",
              "cloudwatch:GetMetricData",
              "eks:DescribeCluster",
              "eks:ListClusters",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  roles = {
    developer = {
      name_suffix = "developer-role"
      description = "Developer read-only role for application debugging"
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
                "sts:ExternalId" = "developer-access"
              }
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      custom_policy_attachments = ["developer_readonly"]
      tags = {
        Role = "Developer"
        Access = "ReadOnly"
        Scope = "Global"
      }
    }
  }
}