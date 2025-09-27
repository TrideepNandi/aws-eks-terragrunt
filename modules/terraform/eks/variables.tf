variable "context" {
  description = "Context variables"
  type = object({
    aws_account_name = optional(string, "")
    aws_region       = optional(string, "")
    aws_region_short = string

    group_name       = string
    project_name     = string
    project_code     = string
    environment_name = string

    workload_name  = optional(string, "")
    instance_index = number
    tags           = optional(map(string), {})
  })
}

variable "iam_assumable_roles" {
  description = "Custom IAM assumable roles"
  type = map(object({
    id   = string
    arn  = string
    name = string
  }))
  default = {}
}

variable "eks" {
  description = "EKS configuration"
  type = object({
    # Cluster configuration
    cluster_version                       = optional(string, "1.30")
    cluster_enabled_log_types             = optional(list(string), ["api", "audit", "authenticator"])
    authentication_mode                   = optional(string, "API_AND_CONFIG_MAP")
    cluster_upgrade_policy                = optional(any, {})
    cluster_additional_security_group_ids = optional(list(string), [])

    control_plane_subnet_ids             = optional(list(string), [])
    subnet_ids                           = optional(list(string), [])
    cluster_endpoint_public_access       = optional(bool, false)
    cluster_endpoint_private_access      = optional(bool, true)
    cluster_endpoint_public_access_cidrs = optional(list(string), ["0.0.0.0/0"])
    cluster_ip_family                    = optional(string, "ipv4")
    cluster_service_ipv4_cidr            = optional(string)
    cluster_service_ipv6_cidr            = optional(string)

    outpost_config                             = optional(any, {})
    cluster_encryption_config                  = optional(any, { resources = ["secrets"] })
    attach_cluster_encryption_policy           = optional(bool, true)
    cluster_tags                               = optional(map(string), {})
    create_cluster_primary_security_group_tags = optional(bool, true)
    cluster_timeouts                           = optional(map(string), {})
    bootstrap_self_managed_addons              = optional(bool)

    # Access configuration
    access_entries                           = optional(any, {})
    enable_cluster_creator_admin_permissions = optional(bool, false)

    # KMS Key configuration
    create_kms_key                    = optional(bool, true)
    kms_key_description               = optional(string)
    kms_key_deletion_window_in_days   = optional(number)
    enable_kms_key_rotation           = optional(bool)
    kms_key_enable_default_policy     = optional(bool, true)
    kms_key_owners                    = optional(list(string), [])
    kms_key_administrators            = optional(list(string), [])
    kms_key_users                     = optional(list(string), [])
    kms_key_service_users             = optional(list(string), [])
    kms_key_source_policy_documents   = optional(list(string), [])
    kms_key_override_policy_documents = optional(list(string), [])
    kms_key_aliases                   = optional(list(string), [])

    # CloudWatch configuration
    create_cloudwatch_log_group            = optional(bool, true)
    cloudwatch_log_group_retention_in_days = optional(number, 90)
    cloudwatch_log_group_kms_key_id        = optional(string)
    cloudwatch_log_group_class             = optional(string, null)
    cloudwatch_log_group_tags              = optional(map(string), {})

    # Cluster Security Group configuration
    create_cluster_security_group           = optional(bool, true)
    cluster_security_group_id               = optional(string, "")
    vpc_id                                  = optional(string)
    cluster_security_group_name             = optional(string)
    cluster_security_group_use_name_prefix  = optional(bool, true)
    cluster_security_group_description      = optional(string, "EKS cluster security group")
    cluster_security_group_additional_rules = optional(any, {})
    cluster_security_group_tags             = optional(map(string), {})

    # EKS IP6 CNI Policy configuration
    create_cni_ipv6_iam_policy = optional(bool, false)

    # Node Security Group configuration
    create_node_security_group                   = optional(bool, true)
    node_security_group_id                       = optional(string, "")
    node_security_group_name                     = optional(string)
    node_security_group_use_name_prefix          = optional(bool, true)
    node_security_group_description              = optional(string, "EKS node shared security group")
    node_security_group_additional_rules         = optional(any, {})
    node_security_group_enable_recommended_rules = optional(bool, true)
    node_security_group_tags                     = optional(map(string), {})
    enable_efa_support                           = optional(bool, false)

    # IRSA configuration
    enable_irsa                     = optional(bool, true)
    openid_connect_audiences        = optional(list(string), [])
    include_oidc_root_ca_thumbprint = optional(bool, true)
    custom_oidc_thumbprints         = optional(list(string), [])

    # Cluster IAM Roles configuration
    create_iam_role                           = optional(bool, true)
    iam_role_arn                              = optional(string)
    iam_role_name                             = optional(string)
    iam_role_use_name_prefix                  = optional(bool, true)
    iam_role_path                             = optional(string)
    iam_role_description                      = optional(string)
    iam_role_permissions_boundary             = optional(string)
    iam_role_additional_policies              = optional(map(string), {})
    iam_role_tags                             = optional(map(string), {})
    cluster_encryption_policy_use_name_prefix = optional(bool, true)
    cluster_encryption_policy_name            = optional(string)
    cluster_encryption_policy_description     = optional(string)
    cluster_encryption_policy_path            = optional(string)
    cluster_encryption_policy_tags            = optional(map(string), {})
    dataplane_wait_duration                   = optional(string, "30s")

    # EKS Addons configuration
    cluster_addons = optional(any, {
      coredns = {
        most_recent = true
      }
      eks-pod-identity-agent = {
        most_recent = true
      }
      kube-proxy = {
        most_recent = true
      }
      vpc-cni = {
        most_recent = true
      }
    })
    cluster_addons_timeouts = optional(map(string), {})

    # EKS Identity Provider configuration
    cluster_identity_providers = optional(any, {})

    # Fargate Profile configuration
    fargate_profiles         = optional(any, {})
    fargate_profile_defaults = optional(any, {})

    # Self Managed Node Group configuration
    self_managed_node_groups         = optional(any, {})
    self_managed_node_group_defaults = optional(any, {})

    # EKS Managed Node Group configuration
    eks_managed_node_groups         = optional(any, {})
    eks_managed_node_group_defaults = optional(any, {})
  })
}

variable "eks_pod_identity_association" {
  description = "EKS Pod Identity Association configuration"
  type = map(object({
    role_name       = string
    role_arn        = optional(string, "")
    namespace       = string
    service_account = string
  }))
  default = {}
}

variable "karpenter" {
  description = "Karpenter configuration"
  type = object({
    create       = optional(bool, false)
    cluster_name = optional(string, "")
    tags         = optional(map(string), {})

    # Karpenter controller IAM Role
    create_iam_role                   = optional(bool, true)
    iam_role_name                     = optional(string, "KarpenterController")
    iam_role_use_name_prefix          = optional(bool, true)
    iam_role_path                     = optional(string, "/")
    iam_role_description              = optional(string, "Karpenter controller IAM role")
    iam_role_max_session_duration     = optional(number, null)
    iam_role_permissions_boundary_arn = optional(string, null)
    iam_role_tags                     = optional(map(string), {})
    iam_policy_name                   = optional(string, "KarpenterController")
    iam_policy_use_name_prefix        = optional(bool, true)
    iam_policy_path                   = optional(string, "/")
    iam_policy_description            = optional(string, "Karpenter controller IAM policy")
    iam_policy_statements             = optional(any, [])
    iam_role_policies                 = optional(map(string), {})
    ami_id_ssm_parameter_arns         = optional(list(string), [])
    enable_pod_identity               = optional(bool, true)
    enable_v1_permissions             = optional(bool, true)

    # IAM Role for Service Account (IRSA)
    enable_irsa                     = optional(bool, false)
    irsa_oidc_provider_arn          = optional(string, "")
    irsa_namespace_service_accounts = optional(list(string), ["karpenter:karpenter"])
    irsa_assume_role_condition_test = optional(string, "StringEquals")

    # Pod Identity Association
    create_pod_identity_association = optional(bool, false)
    namespace                       = optional(string, "karpenter")
    service_account                 = optional(string, "karpenter")

    # Node Termination Queue
    enable_spot_termination                 = optional(bool, true)
    queue_name                              = optional(string, null)
    queue_managed_sse_enabled               = optional(bool, true)
    queue_kms_master_key_id                 = optional(string, null)
    queue_kms_data_key_reuse_period_seconds = optional(number, null)

    # Node IAM Role
    create_node_iam_role               = optional(bool, true)
    cluster_ip_family                  = optional(string, "ipv4")
    node_iam_role_arn                  = optional(string, null)
    node_iam_role_name                 = optional(string, null)
    node_iam_role_use_name_prefix      = optional(bool, true)
    node_iam_role_path                 = optional(string, "/")
    node_iam_role_description          = optional(string, null)
    node_iam_role_max_session_duration = optional(number, null)
    node_iam_role_permissions_boundary = optional(string, null)
    node_iam_role_attach_cni_policy    = optional(bool, true)
    node_iam_role_additional_policies  = optional(map(string), {})
    node_iam_role_tags                 = optional(map(string), {})

    # Access Entry
    create_access_entry = optional(bool, true)
    access_entry_type   = optional(string, "EC2_LINUX")

    # Node IAM Instance Profile
    create_instance_profile = optional(bool, false)

    # Event Bridge Rules
    rule_name_prefix = optional(string, "Karpenter")
  })
  default = {}
}