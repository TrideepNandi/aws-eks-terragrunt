# Kubernetes Cluster Access Guide

This guide provides step-by-step instructions for accessing your EKS clusters after deployment.

## 🎯 Overview

Your infrastructure includes 4 EKS clusters across 3 regions:
- **us-west-2**: Application cluster (name varies based on configuration)
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
3. ✅ **IAM users and roles** deployed
4. ✅ **EKS clusters** deployed with access entries
5. ✅ **AWS profiles** configured

## 🚀 Step-by-Step Access Guide

### **Step 1: Deploy Infrastructure**

```bash
# 1. Deploy IAM users and roles
./script.sh deploy iam

# 2. Deploy EKS clusters (this will take 15-20 minutes)
./script.sh deploy eks

# 3. Verify deployment
./script.sh validate all
```

### **Step 2: Setup AWS Profiles**

```bash
# Run the AWS profile setup script
./setup-aws-profiles.sh

# Follow the prompts to enter:
# - AWS Account ID
# - DevOps user access keys
# - Developer user access keys
```

### **Step 3: Get IAM User Access Keys**

```bash
# Get the access keys from Terraform output
cd iam/
terragrunt output access_keys

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

### **Step 4: Configure AWS Profiles Manually (Alternative)**

If you prefer manual setup, add these to your `~/.aws/credentials`:

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

### **Step 5: Test AWS Access**

```bash
# Test DevOps access
export AWS_PROFILE=eks-devops
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AROA...:botocore-session-...",
#     "Account": "YOUR_ACCOUNT_ID",
#     "Arn": "arn:aws:sts::YOUR_ACCOUNT_ID:assumed-role/eks-global-devops-role/botocore-session-..."
# }

# Test Developer access
export AWS_PROFILE=eks-developer
aws sts get-caller-identity
```

### **Step 6: Update Kubeconfig for Each Cluster**

```bash
# Set DevOps profile for admin access
export AWS_PROFILE=eks-devops

# First, list your actual cluster names
aws eks list-clusters --region us-west-2
aws eks list-clusters --region us-east-1
aws eks list-clusters --region eu-west-1

# Update kubeconfig for each cluster (replace with your actual cluster names)
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
#           app1-use1   arn:aws:eks:us-east-1:ACCOUNT:cluster/app1-use1-1         arn:aws:eks:us-east-1:ACCOUNT:cluster/app1-use1-1         
#           app2-usw2   arn:aws:eks:us-west-2:ACCOUNT:cluster/app2-usw2-2         arn:aws:eks:us-west-2:ACCOUNT:cluster/app2-usw2-2         
#           app3-euw1   arn:aws:eks:eu-west-1:ACCOUNT:cluster/app3-euw1-1         arn:aws:eks:eu-west-1:ACCOUNT:cluster/app3-euw1-1         
#           mgmt-use1   arn:aws:eks:us-east-1:ACCOUNT:cluster/mgmt-use1-1         arn:aws:eks:us-east-1:ACCOUNT:cluster/mgmt-use1-1         

# Test access to each cluster (use your actual aliases)
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
# Switch to this cluster (use your actual context name)
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
# Switch to this cluster (use your actual context name)
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
# Switch to this cluster (use your actual context name)
kubectl config use-context use1-mgmt

# Management tools (these might not be installed yet)
kubectl get pods -n monitoring
kubectl get pods -n logging
kubectl get pods -n argocd

# Check for platform tools
kubectl get namespaces
kubectl get pods --all-namespaces | grep -E "(prometheus|grafana|argocd|vault)"
```

### **EU West 1 - Application Cluster**

```bash
# Switch to this cluster (use your actual context name)
kubectl config use-context euw1-app

# Basic cluster info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# European compliance check
kubectl get nodes --show-labels | grep topology.kubernetes.io/zone
```

## 🔐 Access Levels

### **DevOps Profile (eks-devops)**
- **Full admin access** to all clusters
- Can create, modify, delete resources
- Can access all namespaces
- Can manage cluster configuration

```bash
export AWS_PROFILE=eks-devops
kubectl config use-context usw2-app

# Admin operations
kubectl create namespace test
kubectl delete namespace test
kubectl get secrets --all-namespaces
kubectl logs -n kube-system deployment/coredns
```

### **Developer Profile (eks-developer)**
- **Read-only access** to all clusters
- Can view resources but not modify
- Good for debugging and monitoring

```bash
export AWS_PROFILE=eks-developer
kubectl config use-context usw2-app

# Read-only operations
kubectl get pods --all-namespaces
kubectl describe node
kubectl logs deployment/my-app
kubectl get events --all-namespaces

# These will fail (no permissions)
kubectl create namespace test  # ❌ Forbidden
kubectl delete pod my-pod      # ❌ Forbidden
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
# Quick context switching (use your actual context names)
kubectl config use-context usw2-app   # US West 2
kubectl config use-context use1-app   # US East 1 App
kubectl config use-context use1-mgmt  # US East 1 Management
kubectl config use-context euw1-app   # EU West 1

# Current context
kubectl config current-context

# Rename contexts for easier use (replace with your actual cluster names)
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
   # Verify IAM role assumption
   aws sts assume-role \
     --role-arn arn:aws:iam::ACCOUNT:role/eks-global-devops-role \
     --role-session-name test \
     --external-id devops-access
   ```

4. **"cluster not found" errors**
   ```bash
   # List available clusters
   aws eks list-clusters --region us-west-2
   aws eks list-clusters --region us-east-1
   aws eks list-clusters --region eu-west-1
   ```

### **Debug Commands**

```bash
# Check kubeconfig
kubectl config view
kubectl config get-contexts

# Verify cluster connectivity
kubectl cluster-info dump

# Check AWS EKS access (use your actual cluster name)
aws eks describe-cluster --name YOUR_CLUSTER_NAME --region us-west-2
aws eks list-access-entries --cluster-name YOUR_CLUSTER_NAME --region us-west-2
```

## 🎯 Quick Start Checklist

- [ ] Deploy infrastructure: `./script.sh deploy all`
- [ ] Setup AWS profiles: `./setup-aws-profiles.sh`
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
- [EKS Access Guide](eks-access-guide.md)
- [Deployment Script Guide](deployment-script.md)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)