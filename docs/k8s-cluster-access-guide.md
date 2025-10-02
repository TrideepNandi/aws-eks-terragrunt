# Kubernetes Cluster Access Guide

This guide provides step-by-step instructions for accessing your EKS clusters after deployment using Terramate and Terragrunt.

## 🎯 Overview

Your infrastructure includes 4 EKS clusters across 3 regions:
- **us-west-2**: Application cluster
- **us-east-1**: Application cluster + Management cluster
- **eu-west-1**: Application cluster

To find your actual cluster names, run:
```bash
aws eks list-clusters --region us-west-2
aws eks list-clusters --region us-east-1  
aws eks list-clusters --region eu-west-1
```

## 📋 Prerequisites

Before accessing clusters, ensure you have:
1. ✅ **AWS CLI** installed and configured
2. ✅ **kubectl** installed
3. ✅ **Terramate CLI** installed
4. ✅ **Terragrunt** installed
5. ✅ **IAM users and roles** deployed
6. ✅ **EKS clusters** deployed with access entries
7. ✅ **AWS profiles** configured

## 🚀 Step-by-Step Access Guide

### **Step 1: Deploy Infrastructure**

Follow the deployment order from the [Deployment Guide](deployment-guide.md):

### **Step 2: Get IAM User Access Keys**

```bash
# Get the access keys from Terragrunt output
cd iam/users/
terramate run -- terragrunt output access_keys

# Example output:
# {
#   "devops_user" = {
#     "id" = "AKIA..."
#     "secret" = "..."
#   }
#   "developer_user" = {
#     "id" = "AKIA..."
#     "secret" = "..."
#   }
# }
```

### **Step 3: Configure AWS Profiles**

Add these to your `~/.aws/credentials`:

```ini
[eks-devops-user]
aws_access_key_id = YOUR_DEVOPS_ACCESS_KEY
aws_secret_access_key = YOUR_DEVOPS_SECRET_KEY

[eks-developer-user]
aws_access_key_id = YOUR_DEVELOPER_ACCESS_KEY
aws_secret_access_key = YOUR_DEVELOPER_SECRET_KEY
```

And to `~/.aws/config`:

```ini
[profile eks-devops]
region = us-east-1
role_arn = arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-devops-role
source_profile = eks-devops-user
external_id = devops-access

[profile eks-developer]
region = us-east-1
role_arn = arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-developer-role
source_profile = eks-developer-user
external_id = developer-access
```

**Note**: Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID from `account.hcl`.

### **Step 4: Assume IAM Roles**

After configuring your AWS profiles, you need to assume the appropriate IAM role for cluster access.

#### **Option A: Using AWS Profile (Automatic Role Assumption)**

The AWS CLI will automatically assume the role when you set the profile:

```bash
# For DevOps (full admin access)
export AWS_PROFILE=eks-devops
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AROA...:botocore-session-...",
#     "Account": "YOUR_ACCOUNT_ID",
#     "Arn": "arn:aws:sts::YOUR_ACCOUNT_ID:assumed-role/eks-global-devops-role/botocore-session-..."
# }

# For Developer (read-only access)
export AWS_PROFILE=eks-developer
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AROA...:botocore-session-...",
#     "Account": "YOUR_ACCOUNT_ID",
#     "Arn": "arn:aws:sts::YOUR_ACCOUNT_ID:assumed-role/eks-global-developer-role/botocore-session-..."
# }
```

#### **Option B: Manual Role Assumption (Advanced)**
If you need to manually assume roles or troubleshoot:

```bash
# Assume DevOps role manually
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-devops-role \
  --role-session-name devops-session

# This returns temporary credentials that you can export:
# {
#     "Credentials": {
#         "AccessKeyId": "ASIA...",
#         "SecretAccessKey": "...",
#         "SessionToken": "...",
#         "Expiration": "2025-10-02T12:00:00Z"
#     }
# }

# Export the temporary credentials (replace with actual values from output)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Verify role assumption
aws sts get-caller-identity
```

```bash
# Assume Developer role manually
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-developer-role \
  --role-session-name developer-session 

# Export the credentials as shown above
```

**Note**: Option A (using profiles) is recommended as it handles role assumption automatically and refreshes credentials when they expire.

### **Step 5: Get Cluster Names from Terragrunt Outputs**

```bash
# Get US-West-2 cluster name
cd us-west-2/app-cluster/k8s/
terramate run -- terragrunt output cluster_name

# Get US-East-1 application cluster name
cd us-east-1/app-cluster/k8s/
terramate run -- terragrunt output cluster_name

# Get US-East-1 management cluster name
cd us-east-1/management-cluster/k8s/
terramate run -- terragrunt output cluster_name

# Get EU-West-1 cluster name
cd eu-west-1/app-cluster/k8s/
terramate run -- terragrunt output cluster_name
```

### **Step 6: Update Kubeconfig for Each Cluster**

```bash
# Set DevOps profile for admin access
export AWS_PROFILE=eks-devops

# Update kubeconfig for each cluster (replace with your actual cluster names from Step 5)
# US West 2 - Application Cluster
aws eks update-kubeconfig --region us-west-2 --name <YOUR_USW2_CLUSTER_NAME> --alias usw2-app

# US East 1 - Application Cluster  
aws eks update-kubeconfig --region us-east-1 --name <YOUR_USE1_APP_CLUSTER_NAME> --alias use1-app

# US East 1 - Management Cluster
aws eks update-kubeconfig --region us-east-1 --name <YOUR_USE1_MGMT_CLUSTER_NAME> --alias use1-mgmt

# EU West 1 - Application Cluster
aws eks update-kubeconfig --region eu-west-1 --name <YOUR_EUW1_CLUSTER_NAME> --alias euw1-app
```

### **Step 7: Verify Cluster Access**

```bash
# List all configured contexts
kubectl config get-contexts

# Expected output:
# CURRENT   NAME        CLUSTER                                                     AUTHINFO                                                    NAMESPACE
#           usw2-app    arn:aws:eks:us-west-2:ACCOUNT:cluster/app2-usw2-1          arn:aws:eks:us-west-2:ACCOUNT:cluster/app2-usw2-1         
#           use1-app    arn:aws:eks:us-east-1:ACCOUNT:cluster/app1-use1-1          arn:aws:eks:us-east-1:ACCOUNT:cluster/app1-use1-1         
#           use1-mgmt   arn:aws:eks:us-east-1:ACCOUNT:cluster/mgmt-use1-1          arn:aws:eks:us-east-1:ACCOUNT:cluster/mgmt-use1-1         
#           euw1-app    arn:aws:eks:eu-west-1:ACCOUNT:cluster/app3-euw1-1          arn:aws:eks:eu-west-1:ACCOUNT:cluster/app3-euw1-1         

# Test access to each cluster
kubectl config use-context usw2-app
kubectl get nodes

kubectl config use-context use1-app
kubectl get nodes

kubectl config use-context use1-mgmt
kubectl get nodes

kubectl config use-context euw1-app
kubectl get nodes
```

## 🔧 Cluster-Specific Commands

### **US West 2 - Application Cluster**

```bash
# Switch to this cluster
kubectl config use-context usw2-app

# Basic cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Check Karpenter
kubectl get pods -n karpenter
kubectl get nodepool
kubectl get nodeclaim

# Check system pods
kubectl get pods -n kube-system
```

### **US East 1 - Application Cluster**

```bash
# Switch to this cluster
kubectl config use-context use1-app

# Basic cluster info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Application workloads
kubectl get deployments --all-namespaces
kubectl get services --all-namespaces
```

### **US East 1 - Management Cluster**

```bash
# Switch to this cluster
kubectl config use-context use1-mgmt

# Management tools (these might not be installed yet)
kubectl get pods -n monitoring
kubectl get pods -n logging
kubectl get pods -n argocd

# Check for platform tools
kubectl get namespaces
kubectl get pods --all-namespaces 
```

### **EU West 1 - Application Cluster**

```bash
# Switch to this cluster
kubectl config use-context euw1-app

# Basic cluster info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# European compliance check
kubectl get nodes --show-labels | grep topology.kubernetes.io/zone
```

## 🔐 Access Levels

### **DevOps Profile (eks-devops)**
- **Role**: `eks-global-devops-role`
- **Full admin access** to all clusters
- Can create, modify, delete resources
- Can access all namespaces
- Can manage cluster configuration

```bash
# Assume DevOps role
export AWS_PROFILE=eks-devops

# Verify role assumption
aws sts get-caller-identity
# Should show: arn:aws:sts::ACCOUNT:assumed-role/eks-global-devops-role/...

# Switch to a cluster
kubectl config use-context usw2-app

# Admin operations
kubectl create namespace test
kubectl delete namespace test
kubectl get secrets --all-namespaces
kubectl logs -n kube-system deployment/coredns
kubectl apply -f deployment.yaml
kubectl scale deployment my-app --replicas=5
```

### **Developer Profile (eks-developer)**
- **Role**: `eks-global-developer-role`
- **Read-only access** to all clusters
- Can view resources but not modify
- Good for debugging and monitoring

```bash
# Assume Developer role
export AWS_PROFILE=eks-developer

# Verify role assumption
aws sts get-caller-identity
# Should show: arn:aws:sts::ACCOUNT:assumed-role/eks-global-developer-role/...

# Switch to a cluster
kubectl config use-context usw2-app

# Read-only operations
kubectl get pods --all-namespaces
kubectl describe node
kubectl logs deployment/my-app
kubectl get events --all-namespaces
kubectl top nodes
kubectl get services --all-namespaces

# These will fail (no permissions)
kubectl create namespace test  # ❌ Forbidden
kubectl delete pod my-pod      # ❌ Forbidden
kubectl apply -f deployment.yaml  # ❌ Forbidden
kubectl scale deployment my-app --replicas=5  # ❌ Forbidden
```

### **Switching Between Roles**

```bash
# Switch to DevOps role
export AWS_PROFILE=eks-devops
aws sts get-caller-identity

# Do admin work...
kubectl create namespace production
kubectl apply -f manifests/

# Switch to Developer role for read-only access
export AWS_PROFILE=eks-developer
aws sts get-caller-identity

# View resources only...
kubectl get pods -n production
kubectl logs -f deployment/my-app -n production
```

## 🛠️ Useful Commands

### **Cluster Management**

```bash
# Get cluster information
kubectl cluster-info
kubectl version
kubectl api-resources

# Node management
kubectl get nodes -o wide
kubectl describe node NODE_NAME
kubectl top nodes  # Requires metrics-server

# Pod management
kubectl get pods --all-namespaces -o wide
kubectl get pods -n kube-system
kubectl logs -f POD_NAME -n NAMESPACE
```

### **Context Switching**

```bash
# Quick context switching
kubectl config use-context usw2-app   # US West 2
kubectl config use-context use1-app   # US East 1 App
kubectl config use-context use1-mgmt  # US East 1 Management
kubectl config use-context euw1-app   # EU West 1

# Current context
kubectl config current-context

# Rename contexts for easier use (if needed)
kubectl config rename-context arn:aws:eks:us-west-2:ACCOUNT:cluster/YOUR_CLUSTER_NAME usw2-app
kubectl config rename-context arn:aws:eks:us-east-1:ACCOUNT:cluster/YOUR_APP_CLUSTER_NAME use1-app
kubectl config rename-context arn:aws:eks:us-east-1:ACCOUNT:cluster/YOUR_MGMT_CLUSTER_NAME use1-mgmt
kubectl config rename-context arn:aws:eks:eu-west-1:ACCOUNT:cluster/YOUR_CLUSTER_NAME euw1-app
```

### **Monitoring and Debugging**

```bash
# Check cluster health
kubectl get componentstatuses
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Network debugging
kubectl get services --all-namespaces
kubectl get ingress --all-namespaces
kubectl get networkpolicies --all-namespaces
```

## 🚨 Troubleshooting

### **Common Issues**

1. **"error: You must be logged in to the server (Unauthorized)"**
   ```bash
   # Check AWS profile
   aws sts get-caller-identity
   
   # Re-update kubeconfig (use your actual cluster name)
   aws eks update-kubeconfig --region us-west-2 --name YOUR_CLUSTER_NAME
   ```

2. **"error: exec plugin: invalid apiVersion"**
   ```bash
   # Update AWS CLI
   pip install --upgrade awscli
   
   # Or reinstall kubectl
   brew reinstall kubectl  # macOS
   ```

3. **"AccessDenied" errors**
   ```bash
   # Verify you're using the correct profile
   echo $AWS_PROFILE
   
   # Check current assumed role
   aws sts get-caller-identity
   
   # Verify IAM role assumption works
   aws sts assume-role \
     --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-devops-role \
     --role-session-name test-session 

   # If this fails, check:
   # 1. IAM user has permission to assume the role
   # 2. Role trust policy includes your IAM user ARN
   # 3. External ID matches the role's external ID requirement
   
   # Check role trust policy
   aws iam get-role --role-name eks-global-devops-role \
     --query 'Role.AssumeRolePolicyDocument'
   ```

4. **"cluster not found" errors**
   ```bash
   # List available clusters
   aws eks list-clusters --region us-west-2
   aws eks list-clusters --region us-east-1
   aws eks list-clusters --region eu-west-1
   
   # Or get from Terragrunt outputs
   cd us-west-2/app-cluster/k8s/
   terramate run -- terragrunt output cluster_name
   ```

5. **Terramate/Terragrunt output issues**
   ```bash
   # Refresh outputs
   cd <cluster-path>/k8s/
   terramate run -- terragrunt refresh
   terramate run -- terragrunt output
   ```

### **Debug Commands**

```bash
# Check kubeconfig
kubectl config view
kubectl config get-contexts

# Verify cluster connectivity
kubectl cluster-info dump

# Check current AWS identity
aws sts get-caller-identity

# Verify which role is assumed
aws sts get-caller-identity --query 'Arn' --output text

# Check AWS EKS access
aws eks describe-cluster --name YOUR_CLUSTER_NAME --region us-west-2
aws eks list-access-entries --cluster-name YOUR_CLUSTER_NAME --region us-west-2

# Verify IAM role policies
aws iam get-role --role-name eks-global-devops-role
aws iam list-attached-role-policies --role-name eks-global-devops-role

# Test role assumption for DevOps
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-devops-role \
  --role-session-name debug-session \
  --duration-seconds 3600

# Test role assumption for Developer
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-global-developer-role \
  --role-session-name debug-session \
  --duration-seconds 3600

# Check role trust relationships
aws iam get-role --role-name eks-global-devops-role \
  --query 'Role.AssumeRolePolicyDocument' --output json

aws iam get-role --role-name eks-global-developer-role \
  --query 'Role.AssumeRolePolicyDocument' --output json
```

## 🎯 Quick Start Checklist

- [ ] Deploy S3 backend: `cd s3-backend/ && terramate run -- terragrunt apply`
- [ ] Deploy IAM users: `cd iam/users/ && terramate run -- terragrunt apply`
- [ ] Deploy IAM roles: `cd iam/roles/ && terramate run -- terragrunt apply`
- [ ] Deploy networking for all regions (see Step 1)
- [ ] Deploy EKS clusters for all regions (see Step 1)
- [ ] Configure AWS profiles with IAM user credentials
- [ ] Test AWS access: `aws sts get-caller-identity`
- [ ] Update kubeconfig for all clusters
- [ ] Test cluster access: `kubectl get nodes`
- [ ] Switch between contexts: `kubectl config use-context CONTEXT_NAME`

## 📚 Next Steps

1. **Install cluster tools**: Helm, ArgoCD, Prometheus, etc.
2. **Deploy applications**: Use the clusters for your workloads
3. **Set up monitoring**: Configure observability tools
4. **Implement GitOps**: Set up CI/CD pipelines
5. **Security hardening**: Implement network policies, RBAC, etc.

For more detailed information, see:
- [Deployment Guide](deployment-guide.md)
- [State Management Guide](state-management.md)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terramate Documentation](https://terramate.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
