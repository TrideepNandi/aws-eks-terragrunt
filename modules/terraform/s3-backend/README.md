# S3 Backend Module

Terraform module for creating S3 bucket and DynamoDB table for Terraform state management with encryption, versioning, and locking capabilities.

## 🎯 **Overview**

This module creates the foundational infrastructure for Terraform state management including an S3 bucket for state storage and a DynamoDB table for state locking. It implements security best practices with encryption, versioning, and proper access controls.

## 🚀 **Key Features**

- **Secure State Storage**: S3 bucket with server-side encryption
- **State Locking**: DynamoDB table for preventing concurrent modifications
- **Versioning**: State file history and rollback capabilities
- **Access Control**: Bucket policies and IAM integration
- **Cost Optimization**: Lifecycle policies for old versions
- **Compliance**: Encryption at rest and in transit

## 📋 **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    Terraform State Backend                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────┐    ┌─────────────────────────┐ │
│  │       S3 Bucket         │    │    DynamoDB Table       │ │
│  │                         │    │                         │ │
│  │ • State file storage    │    │ • State locking         │ │
│  │ • Versioning enabled    │    │ • Concurrent protection │ │
│  │ • Server-side encryption│    │ • Lock metadata         │ │
│  │ • Lifecycle policies    │    │ • TTL for cleanup       │ │
│  │ • Access logging        │    │                         │ │
│  └─────────────────────────┘    └─────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 **Usage in Terragrunt**

```hcl
# Example: s3-backend/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../modules/terraform/s3-backend"
}

inputs = {
  context = {
    account_name = "production"
    account_id   = "123456789012"
  }
  
  s3_backend = {
    bucket_name = "terraform-state-production-123456789012"
    
    # Optional configurations
    enable_versioning = true
    enable_encryption = true
    enable_logging    = true
    
    # Lifecycle configuration
    lifecycle_rules = {
      old_versions = {
        enabled = true
        noncurrent_version_expiration = {
          days = 90
        }
      }
    }
  }
  
  dynamodb_table = {
    table_name = "terraform-locks-production"
    
    # Optional configurations
    billing_mode = "PAY_PER_REQUEST"  # or "PROVISIONED"
    
    # For provisioned billing
    read_capacity  = 5
    write_capacity = 5
  }
  
  tags = {
    Environment = "production"
    Purpose     = "terraform-state"
    Project     = "multi-region-eks"
  }
}
```

## 📖 **Configuration Options**

### **Required Variables**
- `context.account_name`: Account name for resource naming
- `context.account_id`: AWS account ID for bucket naming
- `s3_backend.bucket_name`: S3 bucket name for state storage
- `dynamodb_table.table_name`: DynamoDB table name for locking

### **Optional Variables**
- `s3_backend.enable_versioning`: Enable S3 versioning (default: true)
- `s3_backend.enable_encryption`: Enable server-side encryption (default: true)
- `s3_backend.enable_logging`: Enable access logging (default: false)
- `dynamodb_table.billing_mode`: DynamoDB billing mode (default: PAY_PER_REQUEST)
- `tags`: Additional tags for resources

## 🔒 **Security Features**

### **S3 Bucket Security**
- **Server-Side Encryption**: AES256 or KMS encryption
- **Bucket Versioning**: Protect against accidental deletion
- **Public Access Block**: Prevent public access
- **Bucket Policy**: Restrict access to authorized users/roles
- **Access Logging**: Track bucket access (optional)

### **DynamoDB Security**
- **Encryption at Rest**: Server-side encryption enabled
- **IAM Integration**: Role-based access control
- **Point-in-Time Recovery**: Data protection (optional)
- **Backup**: Automated backups (optional)

### **Access Control**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::terraform-state-production-123456789012/*"
    }
  ]
}
```

## 📤 **Outputs**

| Name | Description | Usage |
|------|-------------|-------|
| `s3_bucket.id` | S3 bucket name | Terragrunt backend configuration |
| `s3_bucket.arn` | S3 bucket ARN | IAM policies and cross-account access |
| `s3_bucket.region` | S3 bucket region | Backend configuration |
| `dynamodb_table.name` | DynamoDB table name | Terragrunt backend configuration |
| `dynamodb_table.arn` | DynamoDB table ARN | IAM policies |

## 🔧 **Integration with Terragrunt**

### **Root Terragrunt Configuration**
```hcl
# terragrunt.hcl (root)
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket         = "terraform-state-production-123456789012"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-production"
  }
}
```

### **Automatic State Key Generation**
The backend automatically generates state keys based on directory structure:
```
terraform-state-production-123456789012/
├── us-west-2/app-cluster/iam/terraform.tfstate
├── us-west-2/app-cluster/networking/terraform.tfstate
├── us-west-2/app-cluster/k8s/terraform.tfstate
├── us-east-1/app-cluster/iam/terraform.tfstate
├── us-east-1/management-cluster/iam/terraform.tfstate
└── eu-west-1/app-cluster/k8s/terraform.tfstate
```

## 🛠️ **Lifecycle Management**

### **S3 Lifecycle Rules**
```hcl
lifecycle_rules = {
  old_versions = {
    enabled = true
    
    noncurrent_version_expiration = {
      days = 90  # Delete old versions after 90 days
    }
    
    noncurrent_version_transition = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 60
        storage_class = "GLACIER"
      }
    ]
  }
  
  incomplete_uploads = {
    enabled = true
    
    abort_incomplete_multipart_upload_days = 7
  }
}
```

### **DynamoDB Configuration**
```hcl
dynamodb_table = {
  table_name   = "terraform-locks-production"
  billing_mode = "PAY_PER_REQUEST"  # Cost-effective for most use cases
  
  # For high-traffic environments
  # billing_mode   = "PROVISIONED"
  # read_capacity  = 10
  # write_capacity = 10
  
  # Optional features
  point_in_time_recovery_enabled = true
  deletion_protection_enabled    = true
  
  server_side_encryption = {
    enabled = true
    # kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

## 🔍 **Monitoring and Troubleshooting**

### **CloudWatch Metrics**
- **S3 Metrics**: Bucket size, request metrics, error rates
- **DynamoDB Metrics**: Read/write capacity, throttling, errors

### **Common Issues**
1. **State Lock**: If Terraform operations fail, locks may persist
   ```bash
   # Force unlock (use with caution)
   terragrunt force-unlock <lock-id>
   ```

2. **Permissions**: Ensure IAM roles have proper S3 and DynamoDB permissions
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::terraform-state-production-123456789012",
           "arn:aws:s3:::terraform-state-production-123456789012/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:DeleteItem"
         ],
         "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-locks-production"
       }
     ]
   }
   ```

3. **Cross-Region Access**: Ensure S3 bucket region matches Terragrunt configuration

### **Validation Commands**
```bash
# Verify S3 bucket exists and is accessible
aws s3 ls s3://terraform-state-production-123456789012/

# Check DynamoDB table status
aws dynamodb describe-table --table-name terraform-locks-production

# Test state operations
terragrunt plan  # Should work without errors

# Check for active locks
aws dynamodb scan --table-name terraform-locks-production
```

## 📊 **Best Practices**

### **Naming Conventions**
- **S3 Bucket**: `terraform-state-{environment}-{account-id}`
- **DynamoDB Table**: `terraform-locks-{environment}`
- **Consistent Naming**: Use same pattern across all environments

### **Security Best Practices**
1. **Encryption**: Always enable server-side encryption
2. **Versioning**: Enable versioning for state file protection
3. **Access Control**: Use least privilege IAM policies
4. **Cross-Account**: Use separate backends for different accounts
5. **Backup**: Consider cross-region replication for critical environments

### **Cost Optimization**
1. **Lifecycle Policies**: Automatically transition old versions to cheaper storage
2. **DynamoDB Billing**: Use PAY_PER_REQUEST for most use cases
3. **Monitoring**: Set up billing alerts for unexpected costs
4. **Cleanup**: Regularly clean up old state file versions

### **Operational Excellence**
1. **Monitoring**: Set up CloudWatch alarms for backend health
2. **Documentation**: Document backend configuration and access procedures
3. **Disaster Recovery**: Plan for backend restoration procedures
4. **Testing**: Regularly test backup and restore procedures