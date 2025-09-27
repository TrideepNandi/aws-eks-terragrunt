# VPC Module

Terraform module for creating Amazon VPC (Virtual Private Cloud) infrastructure with comprehensive networking components including subnets, gateways, route tables, and security groups.

## 🎯 **Overview**

This module provides a complete VPC networking foundation using the official AWS VPC Terraform module. It creates a production-ready VPC with public and private subnets, internet and NAT gateways, and proper routing configuration optimized for EKS and other AWS services.

## 🚀 **Key Features**

- **Multi-AZ Design**: High availability across multiple availability zones
- **Flexible Subnet Configuration**: Public and private subnets with customizable CIDR blocks
- **Gateway Management**: Internet gateway and NAT gateways for connectivity
- **Route Table Automation**: Automatic route table creation and association
- **Security Group Integration**: Pre-configured security groups for common use cases
- **EKS Optimization**: Proper subnet tagging for EKS cluster integration
- **Cost Controls**: Options for single NAT gateway in development environments

## 📋 **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC (Configurable CIDR)                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   AZ-1a         │  │   AZ-1b         │  │   AZ-1c     │ │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────┤ │
│  │ Public Subnet   │  │ Public Subnet   │  │ Public Subnet│ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────┐ │ │
│  │ │Internet GW  │ │  │ │ NAT Gateway │ │  │ │NAT GW   │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────┘ │ │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────┤ │
│  │ Private Subnet  │  │ Private Subnet  │  │Private Subnet│ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────┐ │ │
│  │ │   Workloads │ │  │ │  Workloads  │ │  │ │Workloads│ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 **Usage**

### **Basic VPC Configuration**
```hcl
module "vpc" {
  source = "../../modules/terraform/vpc"

  context = {
    aws_region       = "us-west-2"
    aws_region_short = "usw2"
    workload_name    = "app"
    instance_index   = 1
  }

  vpc = {
    name = "my-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

    enable_nat_gateway   = true
    enable_vpn_gateway   = false
    enable_dns_hostnames = true
    enable_dns_support   = true
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### **EKS-Optimized Configuration**
```hcl
module "vpc" {
  source = "../../modules/terraform/vpc"

  context = {
    aws_region       = "us-west-2"
    aws_region_short = "usw2"
    workload_name    = "eks-cluster"
    instance_index   = 1
  }

  vpc = {
    name = "eks-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

    # EKS-specific settings
    enable_nat_gateway     = true
    single_nat_gateway     = false  # Multiple NAT gateways for HA
    enable_dns_hostnames   = true
    enable_dns_support     = true
    
    # EKS subnet tagging
    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
    }
    
    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
    }
  }

  tags = {
    Environment = "production"
    Project     = "eks-infrastructure"
    "kubernetes.io/cluster/my-cluster" = "shared"
  }
}
```

## 📖 **Configuration Options**

### **Required Variables**
- `context.aws_region`: AWS region for deployment
- `context.workload_name`: Workload identifier for naming
- `vpc.name`: VPC name
- `vpc.cidr`: VPC CIDR block
- `vpc.azs`: List of availability zones
- `vpc.public_subnets`: List of public subnet CIDR blocks
- `vpc.private_subnets`: List of private subnet CIDR blocks

### **Optional Variables**
- `vpc.enable_nat_gateway`: Enable NAT gateways (default: true)
- `vpc.single_nat_gateway`: Use single NAT gateway (default: false)
- `vpc.enable_vpn_gateway`: Enable VPN gateway (default: false)
- `vpc.enable_dns_hostnames`: Enable DNS hostnames (default: true)
- `vpc.enable_dns_support`: Enable DNS support (default: true)
- `vpc.public_subnet_tags`: Additional tags for public subnets
- `vpc.private_subnet_tags`: Additional tags for private subnets
- `tags`: Common tags for all resources

## 🔒 **Security Features**

### **Network Isolation**
- **Public Subnets**: Internet-accessible for load balancers and NAT gateways
- **Private Subnets**: Isolated subnets for application workloads
- **Route Tables**: Separate routing for public and private subnets

### **Access Control**
- **Security Groups**: Configurable security groups for different tiers
- **NACLs**: Network ACLs for additional security layer (optional)
- **Flow Logs**: VPC flow logs for network monitoring (optional)

## 📤 **Outputs**

| Name | Description | Usage |
|------|-------------|-------|
| `vpc_id` | VPC ID | Resource association |
| `vpc_arn` | VPC ARN | Cross-account access |
| `vpc_cidr_block` | VPC CIDR block | Security group rules |
| `public_subnets` | Public subnet IDs | Load balancers, bastion hosts |
| `private_subnets` | Private subnet IDs | Application workloads |
| `public_subnet_arns` | Public subnet ARNs | IAM policies |
| `private_subnet_arns` | Private subnet ARNs | IAM policies |
| `internet_gateway_id` | Internet gateway ID | Custom routing |
| `nat_gateway_ids` | NAT gateway IDs | Custom routing |
| `nat_public_ips` | NAT gateway public IPs | Firewall rules |
| `azs` | Availability zones | Multi-AZ deployments |
| `public_route_table_ids` | Public route table IDs | Custom routes |
| `private_route_table_ids` | Private route table IDs | Custom routes |

## 🔧 **Advanced Configuration**

### **Multi-Environment Setup**
```hcl
# Production environment
vpc = {
  name = "prod-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/20", "10.0.27.0/20", "10.0.43.0/20"]  # Larger subnets
  
  enable_nat_gateway = true
  single_nat_gateway = false  # High availability
}

# Development environment
vpc = {
  name = "dev-vpc"
  cidr = "10.1.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b"]  # Fewer AZs
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization
}
```

### **Custom Subnet Tagging**
```hcl
vpc = {
  # ... other configuration
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "subnet-type" = "public"
    "tier" = "web"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "subnet-type" = "private"
    "tier" = "application"
  }
}
```

### **VPN Gateway Configuration**
```hcl
vpc = {
  # ... other configuration
  
  enable_vpn_gateway = true
  
  # Optional: Customer gateway configuration
  customer_gateways = {
    main = {
      bgp_asn    = 65000
      ip_address = "203.0.113.12"
    }
  }
}
```

## 🔍 **Integration Examples**

### **EKS Cluster Integration**
```hcl
# EKS cluster using VPC outputs
module "eks" {
  source = "../eks"
  
  cluster_name = "my-cluster"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # Additional EKS configuration
}
```

### **RDS Integration**
```hcl
# RDS subnet group using VPC outputs
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets
  
  tags = {
    Name = "Main DB subnet group"
  }
}
```

### **Application Load Balancer**
```hcl
# ALB using public subnets
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  
  # Additional ALB configuration
}
```

## 🛠️ **Troubleshooting**

### **Common Issues**
1. **CIDR Conflicts**: Ensure CIDR blocks don't overlap with existing VPCs
2. **AZ Availability**: Verify availability zones exist in the target region
3. **Subnet Sizing**: Ensure subnets are large enough for expected workloads
4. **NAT Gateway Limits**: Check NAT gateway limits in your AWS account

### **Validation Commands**
```bash
# Verify VPC creation
aws ec2 describe-vpcs --vpc-ids vpc-12345678

# Check subnet configuration
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345678"

# Verify route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345678"

# Test internet connectivity from private subnet
# (requires instance in private subnet)
ping 8.8.8.8

# Check NAT gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-12345678"
```

## 📊 **Best Practices**

### **CIDR Planning**
- **Production**: Use /16 VPCs for maximum flexibility
- **Development**: Use /16 or /20 VPCs for smaller environments
- **Subnet Sizing**: Plan for growth - use /20 or /24 subnets
- **Reserved Space**: Leave room for additional subnets

### **High Availability**
- **Multi-AZ**: Always use at least 2 availability zones
- **NAT Redundancy**: Use multiple NAT gateways for production
- **Subnet Distribution**: Distribute resources across AZs

### **Cost Optimization**
- **Development**: Use single NAT gateway
- **Production**: Balance cost vs. availability
- **Instance Types**: Consider NAT instances for very low traffic

### **Security**
- **Private Subnets**: Place sensitive workloads in private subnets
- **Security Groups**: Use least privilege principles
- **Flow Logs**: Enable VPC flow logs for monitoring
- **Network Segmentation**: Use multiple subnets for different tiers