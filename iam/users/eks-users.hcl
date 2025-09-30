locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.account_id

  users = {
    eks-developer = {
      name_suffix        = "developer"
      create_access_key  = true
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policies = {
        assume_developer_role = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action   = "sts:AssumeRole"
              Resource = "arn:aws:iam::${local.account_id}:role/eks-global-developer-role"
            }
          ]
        })
      }
      tags = { UserRole = "Developer" }
    }

    eks-devops = {
      name_suffix        = "devops"
      create_access_key  = true
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policies = {
        assume_devops_role = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action   = "sts:AssumeRole"
              Resource = "arn:aws:iam::${local.account_id}:role/eks-global-devops-role"
            }
          ]
        })
      }
      tags = { UserRole = "DevOps" }
    }
  }
}
