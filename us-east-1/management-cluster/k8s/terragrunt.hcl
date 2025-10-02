include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/terraform/eks"
}

# Read common context and region configuration
locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  context_vars = read_terragrunt_config(find_in_parent_folders("context.hcl"))
  aws_region = local.region_vars.locals.aws_region
}

# Generate AWS provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "production"
      Component   = "eks"
      Region      = "${local.aws_region}"
      Cluster     = "management"
    }
  }
}
EOF
}

dependency "s3_backend" {
  config_path = "../../../s3-backend"
}

dependency "networking" {
  config_path = "../networking"
  
  mock_outputs = {
    vpc = {
      vpc_id          = "vpc-mock"
      private_subnets = ["subnet-mock-1", "subnet-mock-2", "subnet-mock-3"]
      public_subnets  = ["subnet-mock-pub-1", "subnet-mock-pub-2", "subnet-mock-pub-3"]
    }
    security_groups = {}
    security_group_ids = {}
  }
}

inputs = {
  context = {
    aws_region       = local.aws_region
    aws_region_short = local.region_vars.locals.aws_region_short
    group_name       = local.context_vars.locals.group_name
    project_name     = local.context_vars.locals.project_name
    project_code     = local.context_vars.locals.project_code
    environment_name = local.context_vars.locals.environment_name
    workload_name    = "mgmt"
    instance_index   = 1
    tags             = local.context_vars.locals.common_tags
  }

  eks = {
    cluster_version                 = "1.33"
    cluster_endpoint_public_access  = true
    cluster_endpoint_private_access = true

    vpc_id                   = dependency.networking.outputs.vpc.vpc_id
    control_plane_subnet_ids = dependency.networking.outputs.vpc.private_subnets
    subnet_ids               = dependency.networking.outputs.vpc.private_subnets

    cluster_addons = {
      eks-pod-identity-agent = {
        most_recent = true
      }
      kube-proxy = {
        most_recent = true
      }
      vpc-cni = {
        most_recent = true
      }
      aws-ebs-csi-driver = {
        most_recent = true
        configuration_values = jsonencode({
          sidecars = {
            snapshotter = {
              forceEnable = false
            }
          }
        })
      }
      # Additional addons for management cluster
      aws-load-balancer-controller = {
        most_recent = true
      }
    }

    node_security_group_additional_rules = {
      self_rule = {
        description = "Allow all from self"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
        type        = "ingress"
      }
      ingress_node_port = {
        description = "Node Port for management tools"
        protocol    = "-1"
        from_port   = 30000
        to_port     = 32767
        type        = "ingress"
        cidr_blocks = ["0.0.0.0/0"]
      }
      # Allow access from application clusters
      ingress_from_app_clusters = {
        description = "Allow access from application clusters"
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        type        = "ingress"
        cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]  # App cluster CIDRs
      }
    }

    eks_managed_node_group_defaults = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["m7g.xlarge"]
      ebs_optimized  = true

      metadata_options = {
        http_put_response_hop_limit = 2
      }

      timeouts = {
        create = "5m"
        update = "15m"
        delete = "10m"
      }
    }

    eks_managed_node_groups = {
      karpenter = {
        instance_types = ["t4g.small"]
        min_size       = 1
        max_size       = 1
        desired_size   = 1

        labels = {
          "dedicated" = "karpenter"
        }

        taints = [
          {
            key    = "node-restriction.kubernetes.io/karpenter"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        ]
      }

      # Management tools node group - larger instances for platform tools
      management_tools = {
        instance_types = ["m7g.xlarge"]
        min_size       = 2
        max_size       = 5
        desired_size   = 3

        labels = {
          "node-type" = "management"
          "workload"  = "platform-tools"
        }
      }

      # Monitoring node group - optimized for metrics and logs
      monitoring = {
        instance_types = ["r7g.large"]  # Memory optimized for Prometheus/Grafana
        min_size       = 1
        max_size       = 3
        desired_size   = 2

        labels = {
          "node-type" = "monitoring"
          "workload"  = "observability"
        }

        taints = [
          {
            key    = "workload"
            value  = "monitoring"
            effect = "NO_SCHEDULE"
          }
        ]
      }
    }


    cluster_tags = {
      Purpose = "Management Cluster"
      Workload = "Platform Tools"
    }

    create_kms_key                         = true
    create_cluster_security_group          = true
    cluster_security_group_use_name_prefix = false
    enable_irsa                            = true
    iam_role_use_name_prefix               = false
  }

  karpenter = {
    create                          = true
    namespace                       = "karpenter"
    queue_name                      = "karpenter-mgmt-queue"
    create_pod_identity_association = true
    node_iam_role_use_name_prefix   = false
    node_iam_role_name              = "karpenter-mgmt-node"
  }
}
