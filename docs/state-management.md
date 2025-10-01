# State Management

## 🎯 **Overview**

This infrastructure implements automated Terraform state management using Terragrunt with dynamic state key generation. State files are automatically organized in S3 with proper locking via DynamoDB, eliminating manual backend setup.

## 📁 **State File Organization**

```
terraform-state-production-123456789012/
├── iam/
│   ├── roles/terraform.tfstate
│   └── users/terraform.tfstate
── us-west-2/
│   └── app-cluster/
│       ├── networking/terraform.tfstate
│       └── k8s/terraform.tfstate
├── us-east-1/
│   ├── app-cluster/
│   │   ├── networking/terraform.tfstate
│   │   └── k8s/terraform.tfstate
│   └── management-cluster/
│       ├── networking/terraform.tfstate
│       └── k8s/terraform.tfstate
└── eu-west-1/
    └── app-cluster/
        ├── networking/terraform.tfstate
        └── k8s/terraform.tfstate
```

### **State File Contents by Type**

#### **IAM State Files** (`iam/terraform.tfstate`)
- **IAM Roles**: DevOps and Developer roles with appropriate permissions
- **IAM Policies**: Custom managed policies for each role type
- **OIDC Providers**: Identity providers for IRSA (IAM Roles for Service Accounts)
- **Policy Attachments**: Managed and custom policy associations
- **Trust Relationships**: Role assumption policies for users and service accounts
- **Cross-Account Access**: Role assumption across AWS accounts (if configured)

#### **Networking State Files** (`networking/terraform.tfstate`)
- **VPC Configuration**: Virtual Private Cloud with multi-AZ design
- **Subnets**: Public and private subnets optimized for EKS workloads
- **Gateways**: Internet and NAT gateways for connectivity
- **Route Tables**: Routing configuration for public and private traffic
- **Security Groups**: Network access control for EKS clusters and applications
- **VPC Endpoints**: Private connectivity to AWS services (if configured)
- **Flow Logs**: VPC traffic monitoring (if enabled)

#### **EKS State Files** (`k8s/terraform.tfstate`)
- **EKS Cluster**: Kubernetes control plane configuration
- **Node Groups**: Managed node groups with auto-scaling
- **Karpenter Resources**: Dynamic node provisioning configuration
- **EKS Add-ons**: VPC CNI, EBS CSI, Pod Identity Agent, AWS Load Balancer Controller
- **Access Entries**: IAM role integration for cluster access
- **IRSA Configuration**: Service account to IAM role mappings
- **Cluster Security**: Security group rules and network policies

#### **S3 Backend State Files** (`s3-backend/terraform.tfstate`)
- **S3 Bucket**: Terraform state storage with encryption and versioning
- **DynamoDB Table**: State locking mechanism with TTL configuration
- **Bucket Policies**: Access control and security policies
- **Lifecycle Rules**: Automated cleanup of old state versions
- **Replication**: Cross-region replication (if configured)

## 🔧 **Dynamic Key Generation**

State keys are automatically generated based on directory structure:

| Directory Path | Generated State Key |
|---|---|
| `us-west-2/iam/` | `us-west-2/app-cluster/iam/terraform.tfstate` |
| `us-west-2/app-cluster/networking/` | `us-west-2/app-cluster/networking/terraform.tfstate` |
| `us-east-1/management-cluster/iam/` | `us-east-1/management-cluster/iam/terraform.tfstate` |

## ✅ **Benefits**

- **No Static Keys**: Everything generated dynamically
- **Consistent Structure**: Predictable organization
- **Easy Scaling**: Add regions without updating keys
- **Clean Separation**: Each component has its own state

## 🔄 **Adding New Components**

### **New Region**
```bash
# Create directory structure
mkdir -p ap-south-1/{region.hcl,terragrunt.hcl}
mkdir -p ap-south-1/iam-roles/roles/
mkdir -p ap-south-1/app-cluster/{networking,k8s}

# State keys generated automatically:
# ap-south-1/app-cluster/iam/terraform.tfstate
# ap-south-1/app-cluster/networking/terraform.tfstate
# ap-south-1/app-cluster/k8s/terraform.tfstate
```

### **New Cluster Type**
```bash
# Create new cluster type
mkdir -p us-west-2/data-cluster/{iam,networking,k8s}

# State keys generated automatically:
# us-west-2/data-cluster/iam/terraform.tfstate
# us-west-2/data-cluster/networking/terraform.tfstate
# us-west-2/data-cluster/k8s/terraform.tfstate
```

## 🛠️ **Backend Configuration**

### **Automatic Backend Setup**
The root `terragrunt.hcl` handles all backend configuration automatically:

- **S3 Bucket**: `terraform-state-production-{account-id}`
- **DynamoDB Table**: `terraform-locks-production`
- **Encryption**: AES256 server-side encryption
- **Versioning**: Enabled for state file history
- **Locking**: Prevents concurrent modifications

### **First-Time Setup**
```bash
# No manual setup required! Just run:
cd us-west-2/iam-roles/
terragrunt plan

# Terragrunt will prompt:
# "S3 bucket doesn't exist, create it? (y/n)"
# Type 'y' and Terragrunt creates everything automatically
```

### **Backend Features**
- **Zero Configuration**: No manual S3 bucket or DynamoDB setup
- **Automatic Creation**: Backend resources created on first use
- **Security**: Encryption at rest and in transit
- **Reliability**: State locking prevents corruption
- **Organization**: Clean state file hierarchy
- **Versioning**: Complete state history with rollback capabilities
- **Cross-Region**: Support for multi-region deployments
- **Cost Optimization**: Lifecycle policies for old state versions
- **Monitoring**: CloudWatch metrics and alarms for backend health
