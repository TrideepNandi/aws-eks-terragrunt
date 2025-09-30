locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id

  policies = {
    developer_eks_readonly = {
      name_suffix  = "developer-eks-readonly"
      description  = "Read-only EKS access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action = [
              "eks:DescribeCluster",
              "eks:ListClusters",
              "eks:ListNodegroups",
              "eks:DescribeNodegroup",
              "logs:DescribeLogGroups",
              "logs:DescribeLogStreams",
              "logs:GetLogEvents",
              "logs:FilterLogEvents",
              "cloudwatch:GetMetricData",
              "cloudwatch:GetMetricStatistics",
              "cloudwatch:ListMetrics",
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
      name_suffix  = "developer-role"
      description  = "Developer read-only EKS role"

      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::${local.account_id}:user/eks-developer"
            }
            Action    = "sts:AssumeRole"
          }
        ]
      })

      custom_policy_attachments = ["developer_eks_readonly"]
      managed_policy_arns       = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]

      tags = {
        Role   = "Developer"
        Scope  = "EKS"
        Access = "ReadOnly"
      }
    }
  }
}
