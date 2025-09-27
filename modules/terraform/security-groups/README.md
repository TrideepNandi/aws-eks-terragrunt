# Security Groups Module

Terraform module for creating and managing AWS Security Groups with predefined rules for common use cases including EKS clusters, databases, load balancers, and application tiers.

## 🎯 **Overview**

This module provides a flexible and reusable way to create AWS Security Groups with common rule patterns. It includes predefined configurations for EKS clusters, databases, web applications, and other common AWS services while allowing for custom rule definitions.

## 🚀 **Key Features**

- **Predefined Patterns**: Common security group configurations for EKS, RDS, ALB, etc.
- **Flexible Rules**: Support for ingress and egress rules with various sources
- **Reference Integration**: Security groups can reference each other
- **CIDR and Security Group Sources**: Support for IP ranges and security group references
- **Port Range Support**: Single ports, port ranges, and protocol-specific rules
- **Tagging Support**: Consistent tagging across all security groups

## 📋 **Common Patterns**

### **EKS Cluster Security Groups**
- **Control Plane**: API server access and node communication
- **Worker Nodes**: Inter-node communication and external access
- **Pod-to-Pod**: Container networking within the cluster

### **Database Security Groups**
- **RDS**: Database access from application tiers
- **ElastiCache**: Cache access with proper port configurations
- **DocumentDB**: MongoDB-compatible database access

### **Load Balancer Security Groups**
- **Application Load Balancer**: HTTP/HTTPS traffic from internet
- **Network Load Balancer**: TCP/UDP traffic routing
- **Internal Load Balancer**: Private traffic distribution

## 🔧 **Usage**

### **Basic Security Group**
```hcl
module "security_groups" {
  source = "../../modules/terraform/security-groups"

  context = {
    aws_region       = "us-west-2"
    workload_name    = "web-app"
    instance_index   = 1
  }

  vpc_id = "vpc-12345678"

  security_groups = {
    web = {
      name        = "web-servers"
      description = "Security group for web servers"
      
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from anywhere"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from anywhere"
        }
      ]
      
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "web-application"
  }
}
```

### **EKS Security Groups**
```hcl
module "eks_security_groups" {
  source = "../../modules/terraform/security-groups"

  context = {
    aws_region       = "us-west-2"
    workload_name    = "eks-cluster"
    instance_index   = 1
  }

  vpc_id = module.vpc.vpc_id

  security_groups = {
    # EKS Control Plane Security Group
    eks_control_plane = {
      name        = "eks-control-plane"
      description = "EKS control plane security group"
      
      ingress_rules = [
        {
          from_port                = 443
          to_port                  = 443
          protocol                 = "tcp"
          source_security_group_id = "eks_worker_nodes"  # Reference by key
          description              = "HTTPS from worker nodes"
        }
      ]
      
      egress_rules = [
        {
          from_port                = 1025
          to_port                  = 65535
          protocol                 = "tcp"
          source_security_group_id = "eks_worker_nodes"
          description              = "All ports to worker nodes"
        }
      ]
    }

    # EKS Worker Nodes Security Group
    eks_worker_nodes = {
      name        = "eks-worker-nodes"
      description = "EKS worker nodes security group"
      
      ingress_rules = [
        {
          from_port                = 1025
          to_port                  = 65535
          protocol                 = "tcp"
          source_security_group_id = "eks_control_plane"
          description              = "All ports from control plane"
        },
        {
          from_port = 0
          to_port   = 0
          protocol  = "-1"
          self      = true
          description = "All traffic from same security group"
        }
      ]
      
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "eks-infrastructure"
  }
}
```

### **Database Security Groups**
```hcl
module "database_security_groups" {
  source = "../../modules/terraform/security-groups"

  context = {
    aws_region       = "us-west-2"
    workload_name    = "database"
    instance_index   = 1
  }

  vpc_id = module.vpc.vpc_id

  security_groups = {
    # PostgreSQL Database
    postgres = {
      name        = "postgres-database"
      description = "PostgreSQL database security group"
      
      ingress_rules = [
        {
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = "application"
          description              = "PostgreSQL from application servers"
        }
      ]
    }

    # Redis Cache
    redis = {
      name        = "redis-cache"
      description = "Redis cache security group"
      
      ingress_rules = [
        {
          from_port                = 6379
          to_port                  = 6379
          protocol                 = "tcp"
          source_security_group_id = "application"
          description              = "Redis from application servers"
        }
      ]
    }

    # Application Servers
    application = {
      name        = "application-servers"
      description = "Application servers security group"
      
      ingress_rules = [
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = "load_balancer"
          description              = "HTTP from load balancer"
        }
      ]
      
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }

    # Load Balancer
    load_balancer = {
      name        = "load-balancer"
      description = "Load balancer security group"
      
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from internet"
        }
      ]
      
      egress_rules = [
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = "application"
          description              = "HTTP to application servers"
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "web-application"
  }
}
```

## 📖 **Configuration Options**

### **Required Variables**
- `context.aws_region`: AWS region for deployment
- `context.workload_name`: Workload identifier for naming
- `vpc_id`: VPC ID where security groups will be created
- `security_groups`: Map of security group configurations

### **Security Group Configuration**
Each security group supports the following options:
- `name`: Security group name
- `description`: Security group description
- `ingress_rules`: List of ingress rules
- `egress_rules`: List of egress rules

### **Rule Configuration**
Each rule supports:
- `from_port`: Starting port number
- `to_port`: Ending port number
- `protocol`: Protocol (tcp, udp, icmp, or -1 for all)
- `cidr_blocks`: List of CIDR blocks (optional)
- `ipv6_cidr_blocks`: List of IPv6 CIDR blocks (optional)
- `source_security_group_id`: Reference to another security group (optional)
- `self`: Allow traffic from same security group (optional)
- `description`: Rule description

## 📤 **Outputs**

| Name | Description | Usage |
|------|-------------|-------|
| `security_groups` | Map of created security groups | Resource association |
| `security_group_ids` | Map of security group IDs | Quick ID reference |
| `security_group_arns` | Map of security group ARNs | IAM policies |

## 🔧 **Advanced Configuration**

### **Port Ranges and Protocols**
```hcl
security_groups = {
  custom_app = {
    name        = "custom-application"
    description = "Custom application with multiple ports"
    
    ingress_rules = [
      # Single port
      {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "HTTP API"
      },
      
      # Port range
      {
        from_port   = 9000
        to_port     = 9999
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "Application port range"
      },
      
      # All ports
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
        description = "All traffic within security group"
      },
      
      # ICMP
      {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "ICMP ping"
      }
    ]
  }
}
```

### **Multiple Source Types**
```hcl
security_groups = {
  multi_source = {
    name        = "multi-source-example"
    description = "Security group with multiple source types"
    
    ingress_rules = [
      # CIDR blocks
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from internet"
      },
      
      # Security group reference
      {
        from_port                = 8080
        to_port                  = 8080
        protocol                 = "tcp"
        source_security_group_id = "load_balancer"
        description              = "HTTP from load balancer"
      },
      
      # Self reference
      {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        self        = true
        description = "MySQL within security group"
      },
      
      # IPv6 CIDR blocks
      {
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        ipv6_cidr_blocks = ["::/0"]
        description      = "HTTPS from IPv6 internet"
      }
    ]
  }
}
```

## 🔍 **Integration Examples**

### **EKS Cluster Integration**
```hcl
# Use security groups with EKS cluster
module "eks" {
  source = "../eks"
  
  cluster_name = "my-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  
  # Use security groups from this module
  cluster_security_group_id = module.security_groups.security_group_ids.eks_control_plane
  node_security_group_id    = module.security_groups.security_group_ids.eks_worker_nodes
}
```

### **RDS Integration**
```hcl
# RDS instance using database security group
resource "aws_db_instance" "main" {
  identifier = "main-database"
  
  engine         = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.micro"
  
  vpc_security_group_ids = [
    module.security_groups.security_group_ids.postgres
  ]
  
  # Other RDS configuration
}
```

### **Load Balancer Integration**
```hcl
# Application Load Balancer using security group
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  
  security_groups = [
    module.security_groups.security_group_ids.load_balancer
  ]
  
  subnets = module.vpc.public_subnets
}
```

## 🛠️ **Troubleshooting**

### **Common Issues**
1. **Circular Dependencies**: Avoid circular references between security groups
2. **Rule Limits**: AWS has limits on rules per security group (60 inbound, 60 outbound)
3. **Port Ranges**: Ensure port ranges are valid (0-65535)
4. **Protocol Specification**: Use correct protocol names (tcp, udp, icmp, -1)

### **Validation Commands**
```bash
# List security groups
aws ec2 describe-security-groups --group-ids sg-12345678

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345678 \
  --query 'SecurityGroups[0].IpPermissions'

# Test connectivity
# From source instance to destination
telnet <destination-ip> <port>

# Check security group associations
aws ec2 describe-instances --instance-ids i-12345678 \
  --query 'Reservations[0].Instances[0].SecurityGroups'
```

## 📊 **Best Practices**

### **Security Best Practices**
1. **Least Privilege**: Only allow necessary ports and sources
2. **Specific Sources**: Use security group references instead of 0.0.0.0/0 when possible
3. **Descriptive Names**: Use clear, descriptive names and descriptions
4. **Regular Review**: Regularly audit security group rules

### **Design Patterns**
1. **Layered Security**: Use multiple security groups for different tiers
2. **Separation of Concerns**: Create separate security groups for different services
3. **Reusable Groups**: Design security groups to be reusable across environments
4. **Documentation**: Document the purpose and rules of each security group

### **Operational Excellence**
1. **Tagging**: Use consistent tagging for all security groups
2. **Monitoring**: Monitor security group changes and usage
3. **Automation**: Use infrastructure as code for all security group changes
4. **Testing**: Test security group rules in development environments first