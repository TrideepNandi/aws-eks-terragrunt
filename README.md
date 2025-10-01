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
1. **AWS CLI** 
2. **Terraform** 
3. **Terragrunt**
4. Terramate 

### **AWS Requirements**
- Valid AWS account with appropriate permissions
- AWS CLI configured with credentials
- Sufficient service limits for EKS, VPC, and EC2 resources

## 🚀 **Quick Start**

### **1. Clone and Configure**
```bash
# Clone the repository
git clone https://github.com/shashwat0309/aws-eks-terragrunt.git
# or
git clone git@github.com:shashwat0309/aws-eks-terragrunt.git
cd aws-eks-terragrunt

# Update account configuration
vim account.hcl
# Replace 026090515070 with your AWS account ID
```

### **2. Deploy Infrastructure**
```bash
# Deploy US-West-2 region
cd us-west-2/
terramate run -- terragrunt plan # Review changes
terramate run -- terragrunt apply --auto-approve # Deploy infrastructure

# Deploy US-East-1 region (includes management cluster)
cd ../us-east-1/
terramate run -- terragrunt apply --auto-approve # Deploy infrastructure

# Deploy EU-West-1 region
cd ../eu-west-1/
terramate run -- terragrunt apply --auto-approve # Deploy infrastructure
```

### 3. User
#### Deploy User and Role
```bash
cd iam/
terramate run -- terragrunt plan # Review changes
terramate run -- terragrunt apply --auto-approve # Deploy Infrastructure

```

#### Get Access Key and Secret Key
```bash
cd iam/
terramate run -- terragrunt output access_keys
# or 
terramate run -- terragrunt outputs 
```

 - Copy the access key and the secret key from the output of the above command and keep it somewhere

#### Configure AWS credentials
- Add a new profile to the aws credentials file (~/.aws/credentials)

```bash
vim ~/.aws/credentials
```

- Update the configuration by appending this to the credentials file
```bash
[eks-devops]
aws_access_key_id =  <access-key> # Replace from the output of the show outputs command
aws_secret_access_key = <secret-key> # Replace from the output of the show outputs command
```

#### Set AWS profile in your shell
```bash
export AWS_PROFILE=eks-devops
```

#### Assume the IAM Role

Use the `sts-assume` role to get temporary credentials:

```bash
aws sts assume-role --role-arn <role-arn> --role-session-name eks-session
```

Then export the credentials returned in the JSON output:
```bash
export AWS_ACCESS_KEY_ID=<Assumed-Access-Key-ID>
export AWS_SECRET_ACCESS_KEY=<Assumed-Secret-Key-ID>
export AWS_SESSION_TOKEN=<Assumed-Session-Token>
```

#### Update the Kubeconfig for the EKS Cluster
```bash
aws eks update-kubeconfig --region <region> --name <eks-cluster-name>
```

### **4. Verify Deployment**
```bash
# Update kubeconfig for cluster access
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
aws eks update-kubeconfig --region eu-west-1 --name <cluster-name>

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

## 📁 **Project Structure**

```

├── README.md                     # Project overview and documentation
├── account.hcl                   # Global AWS account configuration
├── context.hcl                   # Global Terragrunt/Terramate context
├── root.hcl                      # Root configuration
├── region.hcl                    # Root-level region defaults
├── script.sh                     # Deployment automation script
│
├── docs/                         # Documentation
│   ├── deployment-guide.md       # Step-by-step deployment guide
│   ├── deployment-script.md      # Script usage & features
│   ├── k8s-cluster-access-guide.md # Cluster access setup
│   └── state-management.md       # Terraform/Terragrunt state management
│
├── iam/                          # Central IAM management
│   ├── backend.tf                # Remote backend config for IAM
│   ├── terragrunt.hcl            # Root IAM Terragrunt config
│   ├── stack.tm.hcl              # Terramate stack config (if applicable)
│   ├── roles/                    # IAM role definitions
│   │   ├── clusters/             # Cluster-specific IAM roles
│   │   │   ├── app-cluster
│   │   │   └── management-cluster
│   │   ├── common/               # Shared IAM roles
│   │   │   ├── developer.hcl
│   │   │   └── devops.hcl
│   │   ├── stack.tm.hcl
│   │   └── terragrunt.hcl
│   └── users/                    # IAM user definitions
│       ├── eks-users.hcl
│       ├── stack.tm.hcl
│       └── terragrunt.hcl
│
├── modules/terraform/            # Reusable Terraform modules
│   ├── eks/                      # EKS cluster module
│   │   ├── main.tf
│   │   ├── main_karpenter.tf
│   │   ├── main_pod_identity.tf
│   │   ├── locals.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── iam/                      # IAM module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── networking/               # Networking (VPC + subnets)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── s3-backend/               # S3 + DynamoDB backend
│   │   ├── main.tf
│   │   ├── locals.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security-groups/          # Security groups
│   │   └── README.md
│   └── vpc/                      # Core VPC infrastructure
│       └── README.md
│
├── s3-backend/                   # Remote state backend setup
│   ├── terragrunt.hcl
│   ├── stack.tm.hcl
│   ├── terraform.tfstate
│   └── terraform.tfstate.backup
│
├── us-west-2/                    # US-West-2 region
│   ├── region.hcl
│   ├── terragrunt.hcl
│   └── app-cluster/              # Application cluster
│       ├── networking/           # VPC + security groups
│       │   ├── vpc.hcl
│       │   ├── security-groups.hcl
│       │   ├── terragrunt.hcl
│       │   └── stack.tm.hcl
│       └── k8s/                  # EKS cluster
│           ├── terragrunt.hcl
│           ├── stack.tm.hcl
│           └── terragrunt.hcl.bak
│
├── us-east-1/                    # US-East-1 region
│   ├── region.hcl
│   ├── terragrunt.hcl
│   ├── app-cluster/              # Application cluster
│   │   ├── networking/
│   │   │   ├── vpc.hcl
│   │   │   ├── security-groups.hcl
│   │   │   ├── terragrunt.hcl
│   │   │   └── stack.tm.hcl
│   │   └── k8s/
│   │       ├── terragrunt.hcl
│   │       ├── stack.tm.hcl
│   │       └── terragrunt.hcl.bak
│   └── management-cluster/       # Management cluster
│       ├── networking/
│       │   ├── vpc.hcl
│       │   ├── security-groups.hcl
│       │   ├── terragrunt.hcl
│       │   └── stack.tm.hcl
│       └── k8s/
│           ├── terragrunt.hcl
│           ├── stack.tm.hcl
│           └── terragrunt.hcl.bak
│
└── eu-west-1/                    # EU-West-1 region
    ├── region.hcl
    ├── terragrunt.hcl
    └── app-cluster/              # Application cluster
        ├── networking/
        │   ├── vpc.hcl
        │   ├── security-groups.hcl
        │   ├── terragrunt.hcl
        │   └── stack.tm.hcl
        └── k8s/
            ├── terragrunt.hcl
            ├── stack.tm.hcl
            └── terragrunt.hcl.bak
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


### **Script Features**
- ✅ **Automatic Dependency Management**: Enforces proper deployment order
- ✅ **Parallel Execution**: Run independent components simultaneously
- ✅ **Region/Cluster Filtering**: Target specific regions or clusters
- ✅ **Dry Run Mode**: Preview actions without making changes
- ✅ **Status Tracking**: Track deployment progress and dependencies
- ✅ **Colored Output**: Enhanced readability with progress indicators

For complete script documentation, see **[Deployment Script Guide](docs/deployment-script.md)**.

## 📋 **Manual Deployment Strategies**

Deploy entire regions independently for optimal performance and isolation:
```bash
# Deploy IAM user and role first
cd iam/
terramate run -- terragrunt apply --auto-approve

# Deploy US-West-2 region
cd us-west-2/
terramate run -- terragrunt apply --auto-approve

# Deploy US-East-1 region (includes management cluster)
cd ../us-east-1/
terramate run -- terragrunt apply --auto-approve

# Deploy EU-West-1 region
cd ../eu-west-1/
terramate run -- terragrunt apply --auto-approve
```



## 🎉 **What You Get**

### **Infrastructure Components**
- **4 EKS Clusters**: 3 application clusters + 1 management cluster
- **4 VPCs**: Isolated networking per cluster with multi-AZ design
- **8 IAM Roles**: DevOps and Developer roles per region
- **Auto-scaling**: Karpenter for intelligent node provisioning
- **High Availability**: Multi-AZ deployments with redundancy

### **Cluster Details**
|  Region | Purpose | Node Groups | IAM Integration |
|--------|---------|-------------|-----------------|
|  us-west-2 | Applications | Karpenter + Applications | DevOps, Developer |
|  us-east-1 | Applications | Karpenter + Applications | DevOps, Developer |
|  us-east-1 | Management | Karpenter + Management + Monitoring | DevOps, Developer |
|  eu-west-1 | Applications | Karpenter + Applications | DevOps, Developer |


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
