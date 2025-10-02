# Deployment Guide

## 🎯 **Overview**

This guide provides comprehensive deployment strategies for the multi-region EKS infrastructure with integrated IAM role management. All deployments use Terragrunt commands without requiring external scripts, and include proper IAM role creation, OIDC provider configuration, and complete networking setup with security groups.

## 🚀 **Deployment Strategies**

### **Strategy 1: Full Regional Deployment (Recommended)**
Deploy entire regions independently for better performance and isolation.

```bash
# Deploy US-West-2 region
cd us-west-2/
terramate run -- terragrunt apply --auto-approve

# Deploy US-East-1 region (includes management cluster)
cd us-east-1/
terramate run -- terragrunt apply --auto-approve

# Deploy EU-West-1 region
cd eu-west-1/
terramate run -- terragrunt apply --auto-approve
```

### **Strategy 2: Component-Specific Deployment**
Deploy specific components when you need granular control.

```bash
# Deploy only IAM roles across all regions
cd iam && terramate run -- terragrunt apply --auto-approve

# Deploy only networking components
cd us-west-2/app-cluster/networking/ && terramate run -- terragrunt japply --auto-approve
cd us-east-1/app-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
cd us-east-1/management-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
cd eu-west-1/app-cluster/networking/ && terramate run -- terragrunt japply --auto-approve
```


## 📋 **Deployment Order**

Always follow this order to respect dependencies:

1. **IAM Roles** → 2. **Networking** → 3. **EKS Clusters**

### **Step-by-Step Deployment**

#### **1. Setup**
```bash
# Update account ID
vim account.hcl
# Replace 123456789012 with your AWS account ID

# Verify AWS credentials
aws sts get-caller-identity
```

#### **2. Deploy IAM**
```bash
cd iam/ && terramate run -- terragrunt apply --auto-approve
```

#### **3. Deploy Networking (All Regions)**
```bash
cd us-west-2/app-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
cd us-east-1/app-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
cd us-east-1/management-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
cd eu-west-1/app-cluster/networking/ && terramate run -- terragrunt apply --auto-approve
```

#### **4. Deploy EKS (All Regions)**
```bash
cd us-west-2/app-cluster/k8s/ && terramate run -- terragrunt apply --auto-approve
cd us-east-1/app-cluster/k8s/ && terramate run -- terragrunt apply --auto-approve
cd us-east-1/management-cluster/k8s/ && terramate run -- terragrunt apply --auto-approve
cd eu-west-1/app-cluster/k8s/ && terramate run -- terragrunt apply --auto-approve
```

## 🔐 **IAM Roles Management**

### **IAM Role Types**
Each region deploys three types of IAM roles with specific permissions:

#### **DevOps Role**
- **Purpose**: Full administrative access for infrastructure management
- **Permissions**: EKS cluster admin, IAM management, EC2/VPC control, S3/CloudWatch access
- **Usage**: Infrastructure deployment, troubleshooting, emergency access
- **Trust Policy**: Supports both user and service account assumption

#### **Developer Role**
- **Purpose**: Limited access for application development and debugging
- **Permissions**: Read-only EKS access, CloudWatch logs, pod/service viewing
- **Usage**: Application debugging, log analysis, development workflows
- **Restrictions**: Cannot modify cluster configuration or infrastructure


### **IAM Deployment Verification**
```bash
# Verify IAM roles are created
cd us-west-2/iam/
terramate run -- terragrunt output access_keys

# Check role trust relationships
aws iam get-role --role-name eks-usw2-devops-role

# Verify OIDC provider creation
aws iam list-open-id-connect-providers
```

### **OIDC Provider Configuration**
After EKS clusters are deployed, OIDC providers enable IRSA functionality:
```bash
# Get OIDC issuer URL for each cluster
aws eks describe-cluster --name app2-usw2-1 --region us-west-2 \
  --query 'cluster.identity.oidc.issuer' --output text

# Verify OIDC provider exists
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn <oidc-provider-arn>
```

## 🎯 **Regional Management**

Each region can be managed independently:

### **US-West-2 (App Cluster)**
```bash
cd us-west-2/
terramate run -- terragrunt run plan    # Review changes
terramate run -- terragrunt run-all apply   # Deploy all components
```

### **US-East-1 (App + Management)**
```bash
cd us-east-1/
terramate run -- terragrunt run plan    # Review changes
terramate run -- terragrunt run-all apply   # Deploy all components
```

### **EU-West-1 (App Cluster)**
```bash
cd eu-west-1/
terramate run -- terragrunt run plan    # Review changes
terramate run -- terragrunt run-all apply   # Deploy all components
```

### **Update OIDC Provider IDs**
After EKS clusters are deployed, update OIDC provider IDs in IAM configurations:

```bash
# Get OIDC issuer ID from EKS cluster
aws eks describe-cluster --name app2-usw2-1 --region us-west-2 \
  --query 'cluster.identity.oidc.issuer' --output text

# Update the PLACEHOLDER_OIDC_ID in role files if using IRSA
# Example: Custom application roles with OIDC integration
```


---
## 🛠️ **Troubleshooting**

### **Common Issues**

1. **State Lock**
   If deployment fails and Terraform state is locked:

```bash
# Unlock the state in the affected stack
cd us-west-2/iam/
terramate run -- terragrunt force-unlock <lock-id>
```

2. **Dependencies Not Resolved**
   Terramate ensures stacks are deployed in the correct order (`IAM → Networking → EKS`).
   If you suspect dependency outputs are missing:

```bash
# Refresh outputs for IAM
cd iam/
terramate run -- terragrunt output

# Re-run with Terramate to force dependency resolution
terramate run -- terragrunt plan
```

3. **OIDC Issues**
   If IRSA roles fail due to missing/incorrect OIDC provider IDs:

```bash
# Get OIDC issuer ID
aws eks describe-cluster --name app2-usw2-1 --region us-west-2 \
  --query 'cluster.identity.oidc.issuer' --output text

# Update IAM configs with the correct issuer
vim iam/roles/<your-irsa-role>.hcl

# Re-apply IAM stack
cd iam/ && terramate run -- terragrunt apply --auto-approve
```

4. **Terramate CLI Errors**
   If you see `stack not found` or `no stack matches path`:

* Ensure you are running inside a **stack directory** (`iam/`, `networking/`, `k8s/`, etc.)
* Use `terramate list` to confirm available stacks
* Use `terramate run -- terragrunt plan` to check stack execution

---

### **Validation**

```bash
# Validate IAM stack
cd iam/
terramate run -- terragrunt validate

# Validate networking or EKS
cd us-west-2/app-cluster/k8s/
terramate run -- terragrunt validate

# Dry-run changes
terramate run -- terragrunt plan
```

