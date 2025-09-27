# Deployment Script Guide

The `script.sh` provides an enhanced, dependency-aware deployment system for the Terragrunt infrastructure with advanced features for managing multi-region AWS deployments.

## Features

- **Dependency Management**: Automatic dependency checking and enforcement
- **Parallel Execution**: Run independent components simultaneously for faster deployments
- **Region/Cluster Filtering**: Deploy specific regions or clusters
- **Dry Run Mode**: Preview actions without making changes
- **Status Tracking**: Track deployment status and dependencies
- **Colored Output**: Enhanced readability with color-coded messages

## Usage

```bash
./script.sh [MODE] [COMPONENTS] [OPTIONS]
```

### Modes

| Mode | Description |
|------|-------------|
| `plan` | Run terragrunt plan (default) |
| `deploy` | Run terragrunt apply |
| `destroy` | Run terragrunt destroy |
| `validate` | Run terragrunt validate |
| `init` | Run terragrunt init only |

### Components

| Component | Description | Dependencies |
|-----------|-------------|--------------|
| `s3-backend` | S3 remote state backend | None |
| `iam` | Global IAM roles | s3-backend |
| `networking` | VPC and networking components | s3-backend, iam |
| `eks` | EKS clusters | s3-backend, iam, networking |
| `region` | All components for specific region | Requires --region |
| `infra` | IAM + Networking + EKS | Respects all dependencies |
| `all` | Everything in proper order | Full dependency chain |

### Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be executed without running |
| `--parallel` | Run independent components in parallel |
| `--skip-deps` | Skip dependency checks |
| `--force` | Force execution even with warnings |
| `--region <region>` | Filter by region (us-east-1, us-west-2, eu-west-1) |
| `--cluster <cluster>` | Filter by cluster (app-cluster, management-cluster) |

## Examples

### Basic Deployment

```bash
# Deploy everything in proper order
./script.sh deploy all

# Plan infrastructure changes
./script.sh plan infra

# Destroy everything (reverse order)
./script.sh destroy all
```

### Region-Specific Deployment

```bash
# Deploy all components for US West 2
./script.sh deploy region --region us-west-2

# Deploy only networking for EU West 1
./script.sh deploy networking --region eu-west-1

# Deploy EKS for specific cluster in US East 1
./script.sh deploy eks --region us-east-1 --cluster app-cluster
```

### Advanced Usage

```bash
# Dry run to see what would be destroyed
./script.sh destroy all --dry-run

# Deploy infrastructure components in parallel
./script.sh deploy infra --parallel

# Force deployment ignoring dependency checks
./script.sh deploy eks --force --skip-deps

# Plan changes for management cluster only
./script.sh plan networking --cluster management-cluster
```

## Dependency Chain

The script enforces the following dependency order:

```
s3-backend
    ↓
   iam
    ↓
networking
    ↓
   eks
```

### Deployment Order (deploy/plan)
1. S3 Backend (remote state)
2. IAM Roles (global)
3. Networking (region-specific)
4. EKS Clusters (depends on networking)

### Destruction Order (destroy)
1. EKS Clusters (first to destroy)
2. Networking (second)
3. IAM Roles (third)
4. S3 Backend (last - everything depends on it)

## Status Tracking

The script maintains deployment status in `.terragrunt-status/` directory:

- `s3-backend.deployed` - S3 backend is deployed
- `iam.deployed` - IAM roles are deployed
- `networking.deployed` - Networking is deployed
- `eks.deployed` - EKS clusters are deployed
- `infra.deployed` - Full infrastructure is deployed
- `all.deployed` - Everything is deployed

## Parallel Execution

When using `--parallel`, independent components run simultaneously:

- **Networking**: All region/cluster combinations run in parallel
- **EKS**: All clusters run in parallel (after networking completes)
- **Not applicable for**: Dependencies (s3-backend → iam) run sequentially

## Region and Cluster Matrix

| Region | App Cluster | Management Cluster |
|--------|-------------|-------------------|
| us-east-1 | ✅ | ✅ |
| us-west-2 | ✅ | ❌ |
| eu-west-1 | ✅ | ❌ |

*Note: Management cluster only exists in us-east-1*

## Error Handling

The script includes comprehensive error handling:

- **Missing dependencies**: Warns and exits unless `--force` is used
- **Invalid paths**: Checks directory existence before execution
- **Tool validation**: Verifies terraform and terragrunt are installed
- **AWS profile**: Warns if AWS_PROFILE is not set

## Prerequisites

Before using the script, ensure:

1. **Tools installed**:
   ```bash
   # Check installations
   terraform --version
   terragrunt --version
   ```

2. **AWS credentials configured**:
   ```bash
   export AWS_PROFILE=your-profile
   aws sts get-caller-identity
   ```

3. **Repository structure**: Ensure all required directories exist

## Troubleshooting

### Common Issues

1. **Dependency errors**:
   ```bash
   # Check what's deployed
   ls -la .terragrunt-status/
   
   # Force deployment (use carefully)
   ./script.sh deploy eks --force
   ```

2. **Parallel execution failures**:
   ```bash
   # Run sequentially instead
   ./script.sh deploy networking
   ```

3. **State lock issues**:
   ```bash
   # Clean cache and retry
   find . -name ".terragrunt-cache" -type d -exec rm -rf {} +
   ./script.sh deploy s3-backend
   ```

### Debug Mode

For detailed debugging, run with verbose output:

```bash
# Enable debug mode
export TG_LOG=DEBUG
./script.sh plan all --dry-run
```

## Best Practices

1. **Always dry-run first**: Use `--dry-run` for destructive operations
2. **Use parallel for speed**: Add `--parallel` for large deployments
3. **Region-specific deployments**: Use `--region` for targeted updates
4. **Check dependencies**: Let the script enforce proper order
5. **Monitor status**: Check `.terragrunt-status/` for deployment state

## Integration with CI/CD

The script is designed for CI/CD integration:

```yaml
# Example GitHub Actions usage
- name: Deploy Infrastructure
  run: |
    export AWS_PROFILE=production
    ./script.sh deploy infra --parallel
  
- name: Validate Changes
  run: |
    ./script.sh validate all --dry-run
```

For more information, see the [Deployment Guide](deployment-guide.md) and [State Management](state-management.md) documentation.