module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  # Cluster configuration
  cluster_name                          = local.eks_name
  cluster_version                       = var.eks.cluster_version
  cluster_enabled_log_types             = var.eks.cluster_enabled_log_types
  authentication_mode                   = var.eks.authentication_mode
  cluster_upgrade_policy                = var.eks.cluster_upgrade_policy
  cluster_additional_security_group_ids = var.eks.cluster_additional_security_group_ids

  control_plane_subnet_ids             = var.eks.control_plane_subnet_ids
  subnet_ids                           = var.eks.subnet_ids
  cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.eks.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
  cluster_ip_family                    = var.eks.cluster_ip_family
  cluster_service_ipv4_cidr            = var.eks.cluster_service_ipv4_cidr
  cluster_service_ipv6_cidr            = var.eks.cluster_service_ipv6_cidr

  outpost_config                             = var.eks.outpost_config
  cluster_encryption_config                  = var.eks.cluster_encryption_config
  attach_cluster_encryption_policy           = var.eks.attach_cluster_encryption_policy
  cluster_tags                               = var.eks.cluster_tags
  create_cluster_primary_security_group_tags = var.eks.create_cluster_primary_security_group_tags
  cluster_timeouts                           = var.eks.cluster_timeouts
  bootstrap_self_managed_addons              = var.eks.bootstrap_self_managed_addons

  # Access configuration
  access_entries                           = var.eks.access_entries
  enable_cluster_creator_admin_permissions = var.eks.enable_cluster_creator_admin_permissions

  # KMS Key configuration
  create_kms_key                    = var.eks.create_kms_key
  kms_key_description               = var.eks.kms_key_description
  kms_key_deletion_window_in_days   = var.eks.kms_key_deletion_window_in_days
  enable_kms_key_rotation           = var.eks.enable_kms_key_rotation
  kms_key_enable_default_policy     = var.eks.kms_key_enable_default_policy
  kms_key_owners                    = var.eks.kms_key_owners
  kms_key_administrators            = var.eks.kms_key_administrators
  kms_key_users                     = var.eks.kms_key_users
  kms_key_service_users             = var.eks.kms_key_service_users
  kms_key_source_policy_documents   = var.eks.kms_key_source_policy_documents
  kms_key_override_policy_documents = var.eks.kms_key_override_policy_documents
  kms_key_aliases                   = var.eks.kms_key_aliases

  # CloudWatch configuration
  create_cloudwatch_log_group            = var.eks.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.eks.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.eks.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class             = var.eks.cloudwatch_log_group_class
  cloudwatch_log_group_tags              = var.eks.cloudwatch_log_group_tags

  # Cluster Security Group configuration
  create_cluster_security_group           = var.eks.create_cluster_security_group
  cluster_security_group_id               = var.eks.cluster_security_group_id
  vpc_id                                  = var.eks.vpc_id
  cluster_security_group_name             = var.eks.cluster_security_group_name
  cluster_security_group_use_name_prefix  = var.eks.cluster_security_group_use_name_prefix
  cluster_security_group_description      = var.eks.cluster_security_group_description
  cluster_security_group_additional_rules = var.eks.cluster_security_group_additional_rules
  cluster_security_group_tags             = var.eks.cluster_security_group_tags

  # EKS IP6 CNI Policy configuration
  create_cni_ipv6_iam_policy = var.eks.create_cni_ipv6_iam_policy

  # Node Security Group configuration
  create_node_security_group                   = var.eks.create_node_security_group
  node_security_group_id                       = var.eks.node_security_group_id
  node_security_group_name                     = var.eks.node_security_group_name
  node_security_group_use_name_prefix          = var.eks.node_security_group_use_name_prefix
  node_security_group_description              = var.eks.node_security_group_description
  node_security_group_additional_rules         = var.eks.node_security_group_additional_rules
  node_security_group_enable_recommended_rules = var.eks.node_security_group_enable_recommended_rules
  node_security_group_tags = merge(var.eks.node_security_group_tags, {
    "karpenter.sh/discovery" = local.eks_name
  })
  enable_efa_support = var.eks.enable_efa_support

  # IRSA configuration
  enable_irsa                     = var.eks.enable_irsa
  openid_connect_audiences        = var.eks.openid_connect_audiences
  include_oidc_root_ca_thumbprint = var.eks.include_oidc_root_ca_thumbprint
  custom_oidc_thumbprints         = var.eks.custom_oidc_thumbprints

  # Cluster IAM Roles configuration
  create_iam_role                           = var.eks.create_iam_role
  iam_role_arn                              = var.eks.iam_role_arn
  iam_role_name                             = var.eks.iam_role_name
  iam_role_use_name_prefix                  = var.eks.iam_role_use_name_prefix
  iam_role_path                             = var.eks.iam_role_path
  iam_role_description                      = var.eks.iam_role_description
  iam_role_permissions_boundary             = var.eks.iam_role_permissions_boundary
  iam_role_additional_policies              = var.eks.iam_role_additional_policies
  iam_role_tags                             = var.eks.iam_role_tags
  cluster_encryption_policy_use_name_prefix = var.eks.cluster_encryption_policy_use_name_prefix
  cluster_encryption_policy_name            = var.eks.cluster_encryption_policy_name
  cluster_encryption_policy_description     = var.eks.cluster_encryption_policy_description
  cluster_encryption_policy_path            = var.eks.cluster_encryption_policy_path
  cluster_encryption_policy_tags            = var.eks.cluster_encryption_policy_tags
  dataplane_wait_duration                   = var.eks.dataplane_wait_duration

  # EKS Addons configuration
  cluster_addons          = var.eks.cluster_addons
  cluster_addons_timeouts = var.eks.cluster_addons_timeouts

  # EKS Identity Provider configuration
  cluster_identity_providers = var.eks.cluster_identity_providers

  # Fargate Profile configuration
  fargate_profiles         = var.eks.fargate_profiles
  fargate_profile_defaults = var.eks.fargate_profile_defaults

  # Self Managed Node Group configuration
  self_managed_node_groups         = var.eks.self_managed_node_groups
  self_managed_node_group_defaults = var.eks.self_managed_node_group_defaults

  # EKS Managed Node Group configuration
  eks_managed_node_groups         = var.eks.eks_managed_node_groups
  eks_managed_node_group_defaults = var.eks.eks_managed_node_group_defaults
}