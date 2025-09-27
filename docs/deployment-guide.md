# Deployment Guide

## 🎯 **Overview**

This guide provides comprehensive deployment strategies for the multi-region EKS infrastructure with integrated IAM role management. All deployments use Terragrunt commands without requiring external scripts, and include proper IAM role creation, OIDC provider configuration, and complete networking setup with security groups.

## 🚀 **Deployment Strategies**

### **Strategy 1: Full Regional Deployment (Recommended)**
Deploy entire regions independently for better performance and isolation.

```bash
# Deploy US-West-2 region
cd us-west-2/
terragrunt run-all apply

# Deploy US-East-1 region (includes management cluster)
cd us-east-1/
terragrunt run-all apply

# Deploy EU-West-1 region
cd eu-west-1/
terragrunt run-all apply
```

### **Strategy 2: Component-Specific Deployment**
Deploy specific components when you need granular control.

```bash
# Deploy only IAM roles across all regions
cd us-west-2/iam-roles/ && terragrunt apply
cd us-east-1/iam-roles/ && terragrunt apply
cd us-east-1/management-cluster/iam/ && terragrunt apply
cd eu-west-1/iam-roles/ && terragrunt apply

# Deploy only networking components
cd us-west-2/app-cluster/networking/ && terragrunt apply
cd us-east-1/app-cluster/networking/ && terragrunt apply
cd us-east-1/management-cluster/networking/ && terragrunt apply
cd eu-west-1/app-cluster/networking/ && terragrunt apply
```

### **Strategy 3: Parallel Regional Deployment**
Deploy multiple regions simultaneously for faster deployment.

```bash
# Open multiple terminals and run in parallel
# Terminal 1:
cd us-west-2/ && terragrunt run-all apply

# Terminal 2:
cd us-east-1/ && terragrunt run-all apply

# Terminal 3:
cd eu-west-1/ && terragrunt run-all apply
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

#### **2. Deploy IAM (All Regions)**
```bash
cd us-west-2/iam-roles/ && terragrunt apply && cd ../..
cd us-east-1/iam-roles/ && terragrunt apply && cd ../..
cd us-east-1/management-cluster/iam/ && terragrunt apply && cd ../../..
cd eu-west-1/iam-roles/ && terragrunt apply && cd ../..
```

#### **3. Deploy Networking (All Regions)**
```bash
cd us-west-2/app-cluster/networking/ && terragrunt apply && cd ../../..
cd us-east-1/app-cluster/networking/ && terragrunt apply && cd ../../..
cd us-east-1/management-cluster/networking/ && terragrunt apply && cd ../../..
cd eu-west-1/app-cluster/networking/ && terragrunt apply && cd ../../..
```

#### **4. Deploy EKS (All Regions)**
```bash
cd us-west-2/app-cluster/k8s/ && terragrunt apply && cd ../../..
cd us-east-1/app-cluster/k8s/ && terragrunt apply && cd ../../..
cd us-east-1/management-cluster/k8s/ && terragrunt apply && cd ../../..
cd eu-west-1/app-cluster/k8s/ && terragrunt apply && cd ../../..
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
cd us-west-2/iam-roles/
terragrunt output

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
terragrunt run-all plan    # Review changes
terragrunt run-all apply   # Deploy all components
```

### **US-East-1 (App + Management)**
```bash
cd us-east-1/
terragrunt run-all apply   # Deploys both app and management clusters
```

### **EU-West-1 (App Cluster)**
```bash
cd eu-west-1/
terragrunt run-all apply   # Deploy EU region
```

## 🔧 **Advanced Deployment Techniques**

### **Selective Component Deployment**
Deploy specific components across multiple regions:

```bash
# Deploy all IAM components
for region in us-west-2 us-east-1 eu-west-1; do
  cd $region/iam-roles/ && terragrunt apply && cd ../..
done

# Deploy management cluster IAM separately
cd us-east-1/management-cluster/iam/ && terragrunt apply
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

## 🛠️ **Troubleshooting**

### **Common Issues**

1. **State Lock**: If deployment fails, check for state locks
   ```bash
   terragrunt force-unlock <lock-id>
   ```

2. **Dependencies**: Ensure IAM is deployed before EKS
   ```bash
   # Check dependency outputs
   cd us-west-2/iam-roles/
   terragrunt output
   ```

3. **OIDC Issues**: Update OIDC IDs after cluster creation
   ```bash
   ./update-oidc-ids.sh
   ```

### **Validation**
```bash
# Validate configuration
cd us-west-2/iam-roles/
terragrunt validate

# Plan before apply
terragrunt plan
```

## 🎉 **Post-Deployment**

After successful deployment:

1. **Update kubeconfig**
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name app2-usw2-1
   ```

2. **Verify cluster access**
   ```bash
   kubectl get nodes
   ```

3. **Deploy applications** using kubectl or your preferred deployment method

## 📊 **Performance Tips**

- **Regional Deployment**: Use regional commands for faster execution
- **Parallel Deployment**: Deploy multiple regions in parallel
- **Component Focus**: Deploy only changed components
- **State Isolation**: Each component has separate state for faster operations
- **Dependency Caching**: Terragrunt caches dependency outputs for faster subsequent runs
- **Module Caching**: Terraform modules are cached locally to speed up initialization

## 🔄 **Maintenance and Updates**

### **Regular Maintenance Tasks**
```bash
# Update Terraform modules
terragrunt init -upgrade

# Check for configuration drift
terragrunt plan --detailed-exitcode

# Update EKS cluster versions
# Edit cluster_version in terragrunt.hcl files, then:
terragrunt apply

# Rotate IAM access keys (if using)
aws iam update-access-key --access-key-id <key-id> --status Inactive
```

### **Monitoring Deployment Health**
```bash
# Check EKS cluster status
aws eks describe-cluster --name <cluster-name> --region <region>

# Verify node groups
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>

# Monitor Karpenter nodes
kubectl get nodes -l karpenter.sh/provisioner-name

# Check IAM role trust relationships
aws iam get-role --role-name <role-name>
```