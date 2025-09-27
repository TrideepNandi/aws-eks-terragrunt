# Multi-Region EKS Infrastructure

Production-ready Terragrunt infrastructure for deploying multi-region Amazon EKS clusters with complete separation of concerns, automated state management, enterprise-grade security, and comprehensive IAM role management.

## 🎯 **Overview**

This infrastructure provides a scalable, secure, and maintainable foundation for running Kubernetes workloads across multiple AWS regions. Built with Terragrunt and Terraform, it implements infrastructure-as-code best practices with proper component isolation, dependency management, and comprehensive IAM role-based access control.

## 🏗️ **Architecture**

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   US-West-2     │  │   US-East-1     │  │   EU-West-1     │
│                 │  │                 │  │                 │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │
│ │ App Cluster │ │  │ │ App Cluster │ │  │ │ App Cluster │ │
│ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │
│                 │  │ ┌─────────────┐ │  │                 │
│                 │  │ │ Mgmt Cluster│ │  │                 │
│                 │  │ └─────────────┘ │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### **Components per Region**
- **IAM**: Streamlined role system (DevOps, Developer) with OIDC providers for IRSA
- **Networking**: VPC with public/private subnets optimized for EKS workloads
- **EKS**: Kubernetes clusters with managed node groups, Karpenter auto-scaling, and comprehensive add-ons

## 🎯 **Key Features**

- ✅ **Multi-Region Deployment**: US-West-2, US-East-1, EU-West-1
- ✅ **Separation of Concerns**: IAM, networking, and EKS managed independently
- ✅ **Dynamic State Management**: Automatic S3 state file organization based on directory structure
- ✅ **Modular Design**: Reusable Terraform modules for consistent deployments
- ✅ **Streamlined IAM**: Role-based access with DevOps and Developer roles
- ✅ **GitOps Ready**: Ready for GitOps integration with proper IRSA support
- ✅ **Auto-scaling**: Karpenter for intelligent node provisioning
- ✅ **High Availability**: Multi-AZ deployments with redundant NAT gateways
- ✅ **Security**: Least-privilege IAM roles, IRSA support, and network isolation

## 📋 **Prerequisites**

### **Required Tools**
1. **AWS CLI** (v2.0+)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Configure AWS credentials
   aws configure
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
   unzip terraform_1.6.6_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify installation
   terraform version
   ```

3. **Terragrunt** (v0.50+)
   ```bash
   # Install Terragrunt
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.8/terragrunt_linux_amd64
   chmod +x terragrunt_linux_amd64
   sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
   
   # Verify installation
   terragrunt version
   ```

### **AWS Requirements**
- Valid AWS account with appropriate permissions
- AWS CLI configured with credentials
- Sufficient service limits for EKS, VPC, and EC2 resources

## 🚀 **Quick Start**

### **1. Clone and Configure**
```bash
# Clone the repository
git clone <repository-url>
cd multi-region-eks-infrastructure

# Update account configuration
vim account.hcl
# Replace 123456789012 with your AWS account ID
```

### **2. Deploy Infrastructure**
```bash
# Deploy US-West-2 region
cd us-west-2/
terragrunt run-all plan    # Review changes
terragrunt run-all apply   # Deploy infrastructure

# Deploy US-East-1 region (includes management cluster)
cd ../us-east-1/
terragrunt run-all apply

# Deploy EU-West-1 region
cd ../eu-west-1/
terragrunt run-all apply
```

### **3. Verify Deployment**
```bash
# Update kubeconfig for cluster access
aws eks update-kubeconfig --region us-west-2 --name app2-usw2-1
aws eks update-kubeconfig --region us-east-1 --name app1-use1-1
aws eks update-kubeconfig --region us-east-1 --name mgmt-use1-1
aws eks update-kubeconfig --region eu-west-1 --name app3-euw1-1

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

## 📁 **Project Structure**

```
├── README.md                           # This file
├── account.hcl                         # AWS account configuration
├── terragrunt.hcl                      # Root Terragrunt configuration
├── docs/                              # Detailed documentation
│   ├── state-management.md            # State file organization
│   └── deployment-guide.md            # Comprehensive deployment guide
├── modules/terraform/                 # Reusable Terraform modules
│   ├── iam-roles/                     # Generic IAM roles module
│   │   ├── README.md                  # Module documentation
│   │   ├── main.tf                    # Module implementation
│   │   ├── variables.tf               # Input variables
│   │   ├── outputs.tf                 # Output values
│   │   └── versions.tf                # Provider requirements
│   ├── eks/                           # EKS cluster module
│   │   └── README.md                  # EKS module documentation
│   └── vpc/                           # VPC networking module
│       └── README.md                  # VPC module documentation
├── us-west-2/                         # US West 2 region
│   ├── region.hcl                     # Region-specific configuration
│   ├── terragrunt.hcl                 # Regional Terragrunt config
│   ├── iam-roles/                     # IAM roles for this region
│   │   ├── terragrunt.hcl
│   │   └── roles/                     # Individual role definitions
│   │       ├── devops.hcl             # DevOps role configuration
│   │       └── developer.hcl          # Developer role configuration
│   └── app-cluster/                   # Application cluster
│       ├── networking/                # VPC and networking
│       │   └── terragrunt.hcl
│       └── k8s/                       # EKS cluster
│           └── terragrunt.hcl
├── us-east-1/                         # US East 1 region
│   ├── region.hcl
│   ├── terragrunt.hcl
│   ├── iam-roles/                     # IAM roles for app cluster
│   │   ├── terragrunt.hcl
│   │   └── roles/                     # Role definitions
│   ├── app-cluster/                   # Application cluster
│   │   ├── networking/
│   │   └── k8s/
│   └── management-cluster/            # Management cluster
│       ├── iam/                       # Separate IAM for management
│       │   ├── terragrunt.hcl
│       │   └── roles/
│       │       ├── devops.hcl         # DevOps role configuration
│       │       └── developer.hcl      # Developer role configuration
│       ├── networking/                # Separate VPC for management
│       │   └── terragrunt.hcl
│       └── k8s/                       # Management EKS cluster
│           └── terragrunt.hcl
└── eu-west-1/                         # EU West 1 region
    ├── region.hcl
    ├── terragrunt.hcl
    ├── iam-roles/                     # IAM roles for EU region
    │   ├── terragrunt.hcl
    │   └── roles/
    └── app-cluster/
        ├── networking/
        └── k8s/
```

## 🔧 **Configuration**

### **Account Setup**
```bash
# Edit account configuration
vim account.hcl

# Update with your AWS account ID
locals {
  account_name = "production"
  account_id   = "YOUR_AWS_ACCOUNT_ID"  # Replace this
}
```

### **Regional Configuration**
Each region has its own configuration in `region.hcl`:
```hcl
# Example: us-west-2/region.hcl
locals {
  aws_region       = "us-west-2"
  aws_region_short = "usw2"
}
```

## � ***Enhanced Deployment Script**

The project includes an advanced deployment script (`script.sh`) with dependency management, parallel execution, and region filtering capabilities.

### **Quick Deployment with Script**
```bash
# Deploy everything with dependency management
./script.sh deploy all

# Deploy specific region
./script.sh deploy region --region us-west-2

# Deploy with parallel execution for speed
./script.sh deploy infra --parallel

# Dry run to preview changes
./script.sh destroy all --dry-run
```

### **Script Features**
- ✅ **Automatic Dependency Management**: Enforces proper deployment order
- ✅ **Parallel Execution**: Run independent components simultaneously
- ✅ **Region/Cluster Filtering**: Target specific regions or clusters
- ✅ **Dry Run Mode**: Preview actions without making changes
- ✅ **Status Tracking**: Track deployment progress and dependencies
- ✅ **Colored Output**: Enhanced readability with progress indicators

For complete script documentation, see **[Deployment Script Guide](docs/deployment-script.md)**.

## 📋 **Manual Deployment Strategies**

### **Strategy 1: Regional Deployment (Recommended)**
Deploy entire regions independently for optimal performance and isolation:
```bash
# Deploy US-West-2 region
cd us-west-2/
terragrunt run-all apply

# Deploy US-East-1 region (includes management cluster)
cd ../us-east-1/
terragrunt run-all apply

# Deploy EU-West-1 region
cd ../eu-west-1/
terragrunt run-all apply
```

### **Strategy 2: Component-Specific Deployment**
Deploy specific infrastructure components across regions:
```bash
# Deploy only IAM roles across all regions
cd us-west-2/iam-roles/ && terragrunt apply
cd ../us-east-1/iam-roles/ && terragrunt apply
cd ../us-east-1/management-cluster/iam/ && terragrunt apply
cd ../../eu-west-1/iam-roles/ && terragrunt apply

# Deploy specific component in specific region
cd us-west-2/app-cluster/networking/
terragrunt apply
```

### **Strategy 3: Ordered Deployment (Initial Setup)**
Follow strict dependency order for first-time deployment:
```bash
# Phase 1: Deploy all IAM roles
cd us-west-2/iam-roles/ && terragrunt apply
cd ../us-east-1/iam-roles/ && terragrunt apply
cd ../us-east-1/management-cluster/iam/ && terragrunt apply
cd ../../eu-west-1/iam-roles/ && terragrunt apply

# Phase 2: Deploy all networking
cd ../us-west-2/app-cluster/networking/ && terragrunt apply
cd ../../us-east-1/app-cluster/networking/ && terragrunt apply
cd ../management-cluster/networking/ && terragrunt apply
cd ../../eu-west-1/app-cluster/networking/ && terragrunt apply

# Phase 3: Deploy all EKS clusters
cd ../../us-west-2/app-cluster/k8s/ && terragrunt apply
cd ../../us-east-1/app-cluster/k8s/ && terragrunt apply
cd ../management-cluster/k8s/ && terragrunt apply
cd ../../eu-west-1/app-cluster/k8s/ && terragrunt apply
```

## 🎉 **What You Get**

### **Infrastructure Components**
- **4 EKS Clusters**: 3 application clusters + 1 management cluster
- **4 VPCs**: Isolated networking per cluster with multi-AZ design
- **8 IAM Roles**: DevOps and Developer roles per region
- **Auto-scaling**: Karpenter for intelligent node provisioning
- **High Availability**: Multi-AZ deployments with redundancy

### **Cluster Details**
| Cluster | Region | Purpose | Node Groups | IAM Integration |
|---------|--------|---------|-------------|-----------------|
| app2-usw2-1 | us-west-2 | Applications | Karpenter + Applications | DevOps, Developer |
| app1-use1-1 | us-east-1 | Applications | Karpenter + Applications | DevOps, Developer |
| mgmt-use1-1 | us-east-1 | Management | Karpenter + Management + Monitoring | DevOps, Developer |
| app3-euw1-1 | eu-west-1 | Applications | Karpenter + Applications | DevOps, Developer |

### **IAM Roles Created**
- **DevOps Role**: Full administrative access across all clusters and AWS services
- **Developer Role**: Read-only access for debugging, monitoring, and application logs

### **Security Features**
- **Role-based Access**: Granular permissions for different user types
- **IRSA Integration**: Service account-based authentication for applications
- **Network Isolation**: Private subnets for worker nodes
- **Encryption**: EBS volumes and secrets encrypted at rest
- **OIDC Providers**: Secure authentication for Kubernetes service accounts

## 📚 **Documentation**

### **Deployment & Operations**
- **[Deployment Script Guide](docs/deployment-script.md)** - Enhanced deployment script with dependency management and parallel execution
- **[State Management](docs/state-management.md)** - Dynamic state file organization and backend configuration
- **[Deployment Guide](docs/deployment-guide.md)** - Comprehensive deployment strategies and troubleshooting

### **Terraform Modules**
- **[IAM Roles Module](modules/terraform/iam-roles/README.md)** - Generic IAM roles module with DevOps and Developer roles
- **[EKS Module](modules/terraform/eks/README.md)** - EKS cluster module with Karpenter and comprehensive add-ons
- **[Networking Module](modules/terraform/networking/README.md)** - Complete VPC networking with EKS optimization
- **[VPC Module](modules/terraform/vpc/README.md)** - Core VPC infrastructure with multi-AZ design
- **[Security Groups Module](modules/terraform/security-groups/README.md)** - Reusable security groups for common patterns
- **[S3 Backend Module](modules/terraform/s3-backend/README.md)** - Terraform state backend with S3 and DynamoDB

## 🛠️ **Troubleshooting**

### **Common Issues**
1. **State Lock**: If deployment fails due to state lock
   ```bash
   terragrunt force-unlock <lock-id>
   ```

2. **Dependencies**: Ensure proper deployment order
   ```bash
   # Check dependency outputs
   cd us-west-2/iam-roles/
   terragrunt output
   ```

3. **AWS Permissions**: Verify AWS credentials and permissions
   ```bash
   aws sts get-caller-identity
   aws iam list-attached-user-policies --user-name <username>
   ```

4. **OIDC Issues**: Update OIDC IDs after cluster creation
   ```bash
   # Get OIDC issuer URL
   aws eks describe-cluster --name app2-usw2-1 --region us-west-2 \
     --query 'cluster.identity.oidc.issuer' --output text
   ```

### **Validation Commands**
```bash
# Validate Terragrunt configuration
terragrunt validate

# Plan before apply
terragrunt plan

# Check for configuration drift
terragrunt plan --detailed-exitcode

# Verify cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔄 **Maintenance**

### **Updates**
```bash
# Update Terraform modules
terragrunt init -upgrade

# Apply configuration changes
terragrunt apply

# Update EKS cluster versions
# (Update cluster_version in terragrunt.hcl files)
```

### **Monitoring**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster information
aws eks describe-cluster --name <cluster-name> --region <region>

# Monitor IAM role usage
aws iam get-role --role-name <role-name>
```

## 🤝 **Contributing**

1. Follow the established directory structure
2. Update documentation for any changes
3. Test changes in a development environment
4. Ensure proper state file organization
5. Add appropriate IAM roles for new components
6. Update module documentation when making changes

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.