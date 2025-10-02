# IAM Roles Module

Generic Terraform module for creating IAM roles, policies, and OIDC providers with complete flexibility.

## 🎯 **Quick Usage**

```hcl
module "iam_roles" {
  source = "../../modules/terraform/iam-roles"

  name_prefix = "my-cluster-"

  # Create custom policies
  policies = {
    my_policy = {
      name_suffix = "custom-policy"
      description = "Custom permissions"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Action = ["s3:GetObject"]
          Resource = "*"
        }]
      })
    }
  }

  # Create roles
  roles = {
    my_role = {
      name_suffix = "worker-role"
      description = "Worker role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = { Service = "ec2.amazonaws.com" }
        }]
      })
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      custom_policy_attachments = ["my_policy"]  # Reference by key, not ARN
    }
  }
}
```

## 📋 **Key Features**

- **Generic Design**: Create any IAM roles and policies
- **Three Policy Types**: AWS managed, custom managed, inline
- **OIDC Support**: For Kubernetes IRSA integration
- **Dynamic Naming**: Configurable prefixes and suffixes
- **No ARNs Needed**: Reference custom policies by key name

## 🔧 **Policy Attachment Types**

| Type | Use For | Reference Method |
|------|---------|------------------|
| `managed_policy_arns` | AWS managed policies | Full ARN |
| `custom_policy_attachments` | Policies created in this module | Policy key name |
| `inline_policies` | Small embedded policies | Policy name + JSON |

## 📚 **Examples**

### **Basic Role**
```hcl
roles = {
  basic = {
    name_suffix = "basic-role"
    description = "Basic role"
    assume_role_policy = jsonencode({...})
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  }
}
```

### **IRSA Role for Kubernetes**
```hcl
roles = {
  k8s_role = {
    name_suffix = "k8s-role"
    description = "Kubernetes service account role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/ABC"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.region.amazonaws.com/id/ABC:sub" = "system:serviceaccount:namespace:sa-name"
          }
        }
      }]
    })
  }
}
```

### **Custom Policy + Role**
```hcl
policies = {
  s3_access = {
    name_suffix = "s3-policy"
    description = "S3 access"
    policy = jsonencode({...})
  }
}

roles = {
  app_role = {
    name_suffix = "app-role"
    description = "Application role"
    assume_role_policy = jsonencode({...})
    custom_policy_attachments = ["s3_access"]  # Use key, not ARN
  }
}
```

## 📖 **Variables**

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `name_prefix` | string | Prefix for all resource names | No |
| `policies` | map(object) | Custom policies to create | No |
| `roles` | map(object) | IAM roles to create | No |
| `oidc_providers` | map(object) | OIDC providers to create | No |
| `tags` | map(string) | Common tags for all resources | No |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `policies` | Map of created policies (arn, name, id) |
| `roles` | Map of created roles (arn, name, id) |
| `oidc_providers` | Map of created OIDC providers (arn, url) |

## 🎯 **Integration**

### **EKS Cluster Integration**
Use IAM roles with EKS clusters for access control:
```hcl
# In EKS cluster configuration
dependency "iam_roles" {
  config_path = "../iam-roles"
}

inputs = {
  eks = {
    access_entries = {
      devops = {
        principal_arn = dependency.iam_roles.outputs.roles.devops.arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    }
  }
}
```

### **IRSA Integration**
Configure service accounts to assume IAM roles:
```hcl
# Application service account configuration
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-service-account
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/eks-use1-app-role
```

### **Application Integration**
Application role for accessing AWS services:
```hcl
# Application cluster IAM configuration
roles = {
  application = {
    name_suffix = "application-role"
    description = "Application service role for AWS access"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Effect = "Allow"
          Principal = {
            Federated = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ABC123"
          }
          Condition = {
            StringEquals = {
              "oidc.eks.us-east-1.amazonaws.com/id/ABC123:sub" = "system:serviceaccount:default:my-app"
              "oidc.eks.us-east-1.amazonaws.com/id/ABC123:aud" = "sts.amazonaws.com"
            }
          }
        }
      ]
    })
    custom_policy_attachments = ["application_s3_access"]
  }
}
```

## 🔧 **Real-World Examples**

### **Complete DevOps Role**
```hcl
module "iam_roles" {
  source = "../../modules/terraform/iam-roles"

  name_prefix = "eks-usw2-"

  policies = {
    devops_additional = {
      name_suffix = "devops-additional"
      description = "Additional DevOps permissions"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "route53:*",
              "acm:*",
              "elasticloadbalancing:*"
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
      description = "DevOps administrative role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::123456789012:root"
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
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/IAMFullAccess"
      ]
      custom_policy_attachments = ["devops_additional"]
    }
  }
}
```

### **IRSA-Enabled Application Role**
```hcl
module "app_iam_roles" {
  source = "../../modules/terraform/iam-roles"

  name_prefix = "app-"

  policies = {
    s3_access = {
      name_suffix = "s3-access"
      description = "S3 bucket access for application"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::my-app-bucket/*"
          }
        ]
      })
    }
  }

  roles = {
    application = {
      name_suffix = "application-role"
      description = "Application service account role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
              Federated = var.oidc_provider_arn
            }
            Condition = {
              StringEquals = {
                "${var.oidc_issuer}:sub" = "system:serviceaccount:default:my-app"
                "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
      custom_policy_attachments = ["s3_access"]
    }
  }
}
```

## 📊 **Best Practices**

### **Security Best Practices**
1. **Least Privilege**: Grant minimal required permissions
2. **External IDs**: Use external IDs for cross-account access
3. **Condition Keys**: Use condition keys to restrict access
4. **Regular Rotation**: Rotate access keys and review permissions
5. **MFA Requirements**: Require MFA for sensitive operations
6. **Session Duration**: Set appropriate session durations for assumed roles
7. **Audit Logging**: Enable CloudTrail for role assumption tracking

### **Naming Conventions**
```hcl
# Consistent naming pattern
name_prefix = "eks-${var.region_short}-"

# Results in names like:
# - eks-usw2-devops-role
# - eks-usw2-developer-role
# - eks-usw2-argocd-role
```

### **Policy Organization**
```hcl
# Group related permissions in custom policies
policies = {
  monitoring = {
    name_suffix = "monitoring-policy"
    description = "CloudWatch and observability permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:*",
            "logs:*",
            "xray:*"
          ]
          Resource = "*"
        }
      ]
    })
  }
  
  networking = {
    name_suffix = "networking-policy"
    description = "VPC and networking permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:Describe*",
            "elasticloadbalancing:*",
            "route53:*"
          ]
          Resource = "*"
        }
      ]
    })
  }
  
  storage = {
    name_suffix = "storage-policy"
    description = "Storage service permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "ebs:*",
            "efs:*"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
```

### **IRSA Best Practices**
1. **Namespace Isolation**: Use specific namespaces in trust policies
2. **Service Account Naming**: Use descriptive service account names
3. **Audience Validation**: Always include "sts.amazonaws.com" in audience
4. **Condition Keys**: Use StringEquals for precise matching
5. **Regular Review**: Audit IRSA configurations regularly

### **Multi-Cluster Access**
```hcl
# DevOps role for cross-cluster management
roles = {
  devops_cross_cluster = {
    name_suffix = "devops-cross-cluster"
    description = "DevOps role for managing multiple clusters"
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
              "sts:ExternalId" = "devops-cross-cluster-access"
            }
          }
        }
      ]
    })
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/PowerUserAccess"
    ]
    custom_policy_attachments = ["cross_cluster_eks_access"]
  }
}
```