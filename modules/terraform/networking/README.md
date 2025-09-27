# Networking Module

Terraform module for creating VPC networking infrastructure optimized for Amazon EKS clusters with multi-AZ design, proper subnet tagging, and security group management.

## 🎯 **Overview**

This module creates a complete VPC networking foundation for EKS clusters including public and private subnets, internet and NAT gateways, route tables, and security groups. It's designed to support both application and management clusters with proper isolation and connectivity.

## 🚀 **Key Features**

- **Multi-AZ VPC**: High availability across multiple availability zones
- **EKS-Optimized Subnets**: Proper tagging for EKS cluster discovery
- **Dual Gateway Design**: Internet gateway for public subnets, NAT gateways for private subnets
- **Security Groups**: Pre-configured security groups for EKS clusters
- **Flexible CIDR**: Configurable IP address ranges for different environments
- **Cost Optimization**: Single NAT gateway option for development environments

## 📋 **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  AZ-1a              │  AZ-1b              │  AZ-1c          │
├─────────────────────────────────────────────────────────────┤
│ Public Subnet       │ Public Subnet       │ Public Subnet   │
│ 10.0.1.0/24         │ 10.0.2.0/24         │ 10.0.3.0/24     │
│ ┌─────────────────┐ │ ┌─────────────────┐ │ ┌─────────────┐ │
│ │ Internet Gateway│ │ │   NAT Gateway   │ │ │ NAT Gateway │ │
│ └─────────────────┘ │ └─────────────────┘ │ └─────────────┘ │
├─────────────────────────────────────────────────────────────┤
│ Private Subnet      │ Private Subnet      │ Private Subnet  │
│ 10.0.11.0/24        │ 10.0.12.0/24        │ 10.0.13.0/24    │
│ ┌─────────────────┐ │ ┌─────────────────┐ │ ┌─────────────┐ │
│ │  EKS Nodes      │ │ │   EKS Nodes     │ │ │  EKS Nodes  │ │
│ └─────────────────┘ │ └─────────────────┘ │ └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 **Usage in Terragrunt**

```hcl
# Example: us-west-2/app-cluster/networking/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/terraform/networking"
}

inputs = {
  context = {
    aws_region       = "us-west-2"
    aws_region_short = "usw2"
    workload_name    = "app2"
    instance_index   = 1
  }
  
  vpc = {
    cidr = "10.0.0.0/16"
    
    azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    
    enable_nat_gateway     = true
    single_nat_gateway     = false  # true for dev, false for prod
    enable_vpn_gateway     = false
    enable_dns_hostnames   = true
    enable_dns_support     = true
  }
  
  tags = {
    Environment = "production"
    Project     = "multi-region-eks"
  }
}
```

## 📖 **Configuration Options**

### **Required Variables**
- `context.aws_region`: AWS region for deployment
- `context.workload_name`: Workload identifier for naming
- `vpc.cidr`: VPC CIDR block
- `vpc.azs`: List of availability zones
- `vpc.public_subnets`: List of public subnet CIDR blocks
- `vpc.private_subnets`: List of private subnet CIDR blocks

### **Optional Variables**
- `vpc.enable_nat_gateway`: Enable NAT gateways (default: true)
- `vpc.single_nat_gateway`: Use single NAT gateway (default: false)
- `vpc.enable_dns_hostnames`: Enable DNS hostnames (default: true)
- `vpc.enable_dns_support`: Enable DNS support (default: true)
- `tags`: Additional tags for resources

## 🎯 **Subnet Tagging for EKS**

The module automatically applies EKS-required tags:

### **Public Subnets**
```hcl
tags = {
  "kubernetes.io/role/elb" = "1"
  "kubernetes.io/cluster/${cluster_name}" = "shared"
}
```

### **Private Subnets**
```hcl
tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "kubernetes.io/cluster/${cluster_name}" = "shared"
}
```

## 🔒 **Security Groups**

### **EKS Cluster Security Group**
- **Purpose**: Control plane to node communication
- **Rules**: 
  - Ingress: HTTPS (443) from nodes
  - Egress: All traffic to nodes

### **EKS Node Security Group**
- **Purpose**: Worker node communication
- **Rules**:
  - Ingress: All traffic from cluster security group
  - Ingress: Node-to-node communication
  - Egress: All traffic (internet access)

### **Additional Security Group**
- **Purpose**: Custom application rules
- **Rules**: Configurable based on requirements

## 📤 **Outputs**

| Name | Description | Usage |
|------|-------------|-------|
| `vpc.vpc_id` | VPC ID | EKS cluster configuration |
| `vpc.vpc_cidr_block` | VPC CIDR block | Security group rules |
| `vpc.public_subnets` | Public subnet IDs | Load balancers, NAT gateways |
| `vpc.private_subnets` | Private subnet IDs | EKS worker nodes |
| `vpc.internet_gateway_id` | Internet gateway ID | Custom routing |
| `vpc.nat_gateway_ids` | NAT gateway IDs | Custom routing |
| `security_groups.cluster` | Cluster security group ID | EKS cluster |
| `security_groups.nodes` | Node security group ID | EKS node groups |

## 🔍 **Integration Examples**

### **EKS Cluster Integration**
```hcl
# In EKS module configuration
dependency "networking" {
  config_path = "../networking"
}

inputs = {
  eks = {
    vpc_id     = dependency.networking.outputs.vpc.vpc_id
    subnet_ids = dependency.networking.outputs.vpc.private_subnets
    
    cluster_security_group_additional_rules = {
      ingress_nodes_443 = {
        description                = "Node groups to cluster API"
        protocol                   = "tcp"
        from_port                  = 443
        to_port                    = 443
        type                       = "ingress"
        source_security_group_id   = dependency.networking.outputs.security_groups.nodes
      }
    }
  }
}
```

### **Load Balancer Integration**
```hcl
# AWS Load Balancer Controller uses subnet tags
# Public subnets: External load balancers
# Private subnets: Internal load balancers

# Example service configuration
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
spec:
  type: LoadBalancer
  # Will use private subnets due to internal scheme
```

## 🔧 **Advanced Configuration**

### **Custom CIDR Ranges**
```hcl
# Large environment with multiple clusters
vpc = {
  cidr = "10.0.0.0/8"  # Large address space
  
  public_subnets = [
    "10.1.0.0/24",   # us-west-2a
    "10.2.0.0/24",   # us-west-2b
    "10.3.0.0/24"    # us-west-2c
  ]
  
  private_subnets = [
    "10.11.0.0/20",  # us-west-2a (4096 IPs)
    "10.12.0.0/20",  # us-west-2b (4096 IPs)
    "10.13.0.0/20"   # us-west-2c (4096 IPs)
  ]
}
```

### **Development Environment**
```hcl
# Cost-optimized for development
vpc = {
  cidr = "10.0.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b"]  # Only 2 AZs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  
  single_nat_gateway = true  # Cost optimization
  enable_vpn_gateway = false
}
```

### **Multi-Cluster Environment**
```hcl
# Separate VPCs for different cluster types
# App cluster VPC
vpc = {
  cidr = "10.0.0.0/16"
  # ... app cluster subnets
}

# Management cluster VPC (separate)
vpc = {
  cidr = "10.1.0.0/16"
  # ... management cluster subnets
}
```

## 🛠️ **Troubleshooting**

### **Common Issues**
1. **Subnet Overlap**: Ensure CIDR blocks don't overlap between VPCs
2. **AZ Availability**: Verify availability zones exist in the region
3. **NAT Gateway Limits**: Check NAT gateway limits in your account
4. **EKS Tagging**: Ensure subnets have proper EKS tags

### **Validation Commands**
```bash
# Verify VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=app2-usw2-1-vpc"

# Check subnet tagging
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345" \
  --query 'Subnets[*].[SubnetId,Tags[?Key==`kubernetes.io/role/elb`].Value]'

# Verify NAT gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-12345"

# Test internet connectivity from private subnet
# (requires EC2 instance in private subnet)
curl -I https://www.google.com
```

## 📊 **Best Practices**

### **CIDR Planning**
- **Production**: Use /16 VPCs with /20 private subnets (4096 IPs each)
- **Development**: Use /16 VPCs with /24 subnets (256 IPs each)
- **Avoid Overlap**: Plan CIDR ranges to prevent conflicts

### **High Availability**
- **Multi-AZ**: Always use at least 2 availability zones
- **NAT Redundancy**: Use multiple NAT gateways for production
- **Subnet Distribution**: Distribute subnets evenly across AZs

### **Cost Optimization**
- **Development**: Use single NAT gateway
- **Production**: Use multiple NAT gateways for redundancy
- **Instance Types**: Consider NAT instances for very low traffic

### **Security**
- **Private Subnets**: Place EKS nodes in private subnets
- **Security Groups**: Use least privilege principles
- **Network ACLs**: Add additional layer if required