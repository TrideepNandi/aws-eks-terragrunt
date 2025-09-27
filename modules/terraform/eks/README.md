# EKS Module

Terraform wrapper module for creating Amazon EKS clusters with managed node groups, Karpenter auto-scaling, and comprehensive add-on support.

## 🎯 **Overview**

This module provides a production-ready EKS cluster configuration using the official AWS EKS Terraform module with optimized settings for multi-region deployments, ARM64 instances, and GitOps workflows.

## 🚀 **Key Features**

- **Managed Control Plane**: EKS cluster with automatic updates and patching
- **Multi-AZ Deployment**: High availability across availability zones
- **ARM64 Optimization**: Graviton processors for cost efficiency
- **Karpenter Integration**: Dynamic node provisioning and scaling
- **Comprehensive Add-ons**: VPC CNI, EBS CSI, Pod Identity Agent
- **Security Groups**: Proper network isolation and access control
- **IRSA Support**: IAM Roles for Service Accounts integration

## 📋 **Cluster Configuration**

### **Node Groups**
- **Karpenter Nodes**: Small instances for Karpenter controller
- **Application Nodes**: Larger instances for application workloads
- **Management Nodes**: Specialized nodes for platform tools (management cluster only)
- **Monitoring Nodes**: Memory-optimized for observability stack (management cluster only)

### **EKS Add-ons**
- **VPC CNI**: Pod networking and IP management
- **EBS CSI Driver**: Persistent volume support
- **Pod Identity Agent**: IRSA functionality
- **Kube Proxy**: Network proxy for services
- **AWS Load Balancer Controller**: (Management cluster only)

### **Instance Types**
- **Karpenter**: t4g.small (ARM64)
- **Applications**: m7g.large (ARM64, general purpose)
- **Management**: m7g.xlarge (ARM64, larger for platform tools)
- **Monitoring**: r7g.large (ARM64, memory optimized)

## 🔧 **Usage in Terragrunt**

```hcl
# Example: us-west-2/app-cluster/k8s/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/terraform/eks"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  context = {
    aws_region       = "us-west-2"
    aws_region_short = "usw2"
    workload_name    = "app2"
    instance_index   = 1
  }
  
  eks = {
    cluster_version = "1.30"
    vpc_id          = dependency.networking.outputs.vpc.vpc_id
    subnet_ids      = dependency.networking.outputs.vpc.private_subnets
    
    eks_managed_node_groups = {
      applications = {
        instance_types = ["m7g.large"]
        min_size       = 2
        max_size       = 10
        desired_size   = 3
      }
    }
    
    enable_irsa = true
  }
  
  karpenter = {
    create = true
    namespace = "karpenter"
  }
}
```

## 📖 **Configuration Options**

### **Required Variables**
- `context.aws_region`: AWS region for deployment
- `context.workload_name`: Workload identifier for naming
- `eks.vpc_id`: VPC ID from networking module
- `eks.subnet_ids`: Subnet IDs for EKS nodes

### **Optional Variables**
- `eks.cluster_version`: Kubernetes version (default: 1.30)
- `eks.enable_irsa`: Enable IRSA support (default: true)
- `karpenter.create`: Enable Karpenter (default: true)

## 🎯 **Integration**

### **Dependencies**
```hcl
# Networking dependency (required)
dependency "networking" {
  config_path = "../networking"
}

# IAM dependency (required)
dependency "iam_roles" {
  config_path = "../iam-roles"
}
```

### **IAM Integration**
The EKS module integrates with IAM roles for cluster access:
```hcl
inputs = {
  eks = {
    # IAM roles for cluster access
    access_entries = {
      devops = {
        kubernetes_groups = []
        principal_arn     = dependency.iam_roles.outputs.roles.devops.arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
      developer = {
        kubernetes_groups = []
        principal_arn     = dependency.iam_roles.outputs.roles.developer.arn
        policy_associations = {
          view = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }
  }
}
```

### **OIDC Integration**
The module outputs OIDC information used by IAM roles:
```hcl
# OIDC issuer URL used in IAM trust policies
cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

# OIDC provider ARN for IRSA
oidc_provider_arn = module.eks.oidc_provider_arn
```

### **Outputs Used by Other Modules**
- `cluster_name`: EKS cluster name for kubectl configuration
- `cluster_endpoint`: Kubernetes API endpoint for applications
- `cluster_oidc_issuer_url`: OIDC issuer for IAM trust relationships
- `cluster_security_group_id`: Security group ID for additional rules
- `oidc_provider_arn`: OIDC provider ARN for IRSA configuration

## 🔍 **Troubleshooting**

### **Common Issues**
1. **Subnet Requirements**: Ensure subnets are properly tagged for EKS
2. **Instance Limits**: Check EC2 instance limits in your AWS account
3. **Karpenter**: Verify Karpenter has proper IAM permissions
4. **Add-ons**: Some add-ons may require specific instance types

### **Validation**
```bash
# Verify cluster is ready
aws eks describe-cluster --name app2-usw2-1 --region us-west-2

# Check node groups
aws eks describe-nodegroup --cluster-name app2-usw2-1 --nodegroup-name applications --region us-west-2

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name app2-usw2-1

# Verify connectivity
kubectl get nodes

# Test IAM role integration
kubectl auth can-i "*" "*" --as-group=system:masters

# Check OIDC provider
aws iam list-open-id-connect-providers
```

## 🔧 **Advanced Configuration**

### **Custom Node Groups**
```hcl
eks_managed_node_groups = {
  # GPU workloads
  gpu_workload = {
    instance_types = ["g5.xlarge", "g5.2xlarge"]
    min_size       = 0
    max_size       = 10
    desired_size   = 2
    
    labels = {
      workload = "gpu"
      "nvidia.com/gpu" = "true"
    }
    
    taints = {
      gpu = {
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
    
    # GPU-optimized AMI
    ami_type = "AL2_x86_64_GPU"
  }

  # Memory-intensive workloads
  memory_optimized = {
    instance_types = ["r7g.large", "r7g.xlarge"]
    min_size       = 1
    max_size       = 20
    desired_size   = 3
    
    labels = {
      workload = "memory-intensive"
    }
    
    taints = {
      dedicated = {
        key    = "workload"
        value  = "memory-intensive"
        effect = "NO_SCHEDULE"
      }
    }
  }

  # Spot instances for cost optimization
  spot_workload = {
    instance_types = ["m7g.large", "m7g.xlarge", "c7g.large"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 50
    desired_size   = 5
    
    labels = {
      workload = "batch"
      capacity = "spot"
    }
    
    taints = {
      spot = {
        key    = "capacity"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }
    }
  }
}
```

### **Karpenter Configuration**
```hcl
karpenter = {
  create    = true
  namespace = "karpenter"
  version   = "v0.32.0"
  
  # Node pools for different workload types
  node_pools = {
    # General purpose ARM64 nodes
    general = {
      requirements = [
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = ["arm64"]
        },
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = ["spot", "on-demand"]
        },
        {
          key      = "node.kubernetes.io/instance-type"
          operator = "In"
          values   = ["m7g.medium", "m7g.large", "m7g.xlarge"]
        }
      ]
      
      limits = {
        cpu = "1000"
      }
      
      disruption = {
        consolidation_policy = "WhenUnderutilized"
        consolidate_after    = "30s"
        expire_after         = "30m"
      }
    }

    # GPU nodes for ML workloads
    gpu = {
      requirements = [
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = ["amd64"]
        },
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = ["on-demand"]  # GPU instances typically on-demand
        },
        {
          key      = "node.kubernetes.io/instance-type"
          operator = "In"
          values   = ["g5.xlarge", "g5.2xlarge", "g5.4xlarge"]
        }
      ]
      
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
      
      limits = {
        cpu = "1000"
      }
    }

    # Spot instances for batch workloads
    spot_batch = {
      requirements = [
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = ["spot"]
        },
        {
          key      = "node.kubernetes.io/instance-type"
          operator = "In"
          values   = ["m7g.large", "m7g.xlarge", "c7g.large", "c7g.xlarge"]
        }
      ]
      
      taints = [
        {
          key    = "capacity"
          value  = "spot"
          effect = "NoSchedule"
        }
      ]
      
      disruption = {
        consolidation_policy = "WhenEmpty"
        consolidate_after    = "10s"
        expire_after         = "10m"  # Shorter for batch workloads
      }
    }
  }
}
```

### **EKS Add-ons Configuration**
```hcl
cluster_addons = {
  vpc-cni = {
    version = "v1.15.1-eksbuild.1"
    configuration_values = jsonencode({
      env = {
        ENABLE_PREFIX_DELEGATION = "true"
        WARM_PREFIX_TARGET       = "1"
      }
    })
  }
  
  aws-ebs-csi-driver = {
    version = "v1.24.0-eksbuild.1"
    service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
  }
  
  aws-efs-csi-driver = {
    version = "v1.7.0-eksbuild.1"
    service_account_role_arn = module.efs_csi_irsa.iam_role_arn
  }
  
  aws-load-balancer-controller = {
    version = "v2.6.0-eksbuild.1"
    service_account_role_arn = module.aws_load_balancer_controller_irsa.iam_role_arn
  }
}
```