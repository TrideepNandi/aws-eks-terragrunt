# Developer role configuration for management cluster
locals {
  policies = {
    developer_readonly = {
      name_suffix = "developer-readonly-policy"
      description = "Developer read-only access for management cluster monitoring"
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
              "cloudwatch:DescribeAlarms",
              "eks:DescribeCluster",
              "eks:ListClusters"
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
      description = "Developer read-only role for management cluster access"
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
                "sts:ExternalId" = "mgmt-developer-access"
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
        Cluster = "Management"
      }
    }
  }
}