variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    name_suffix = string
    description = string
    policy      = string
    path        = optional(string, "/")
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    name_suffix                = string
    description               = string
    max_session_duration      = optional(number, 3600)
    assume_role_policy        = string
    managed_policy_arns       = optional(list(string), [])
    custom_policy_attachments = optional(list(string), [])
    inline_policies          = optional(map(string), {})
    path                     = optional(string, "/")
    tags                     = optional(map(string), {})
  }))
  default = {}
}

variable "oidc_providers" {
  description = "Map of OIDC providers to create"
  type = map(object({
    url             = string
    client_id_list  = optional(list(string), ["sts.amazonaws.com"])
    thumbprint_list = optional(list(string), ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"])
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    name_suffix                = string
    path                      = optional(string, "/")
    managed_policy_arns       = optional(list(string), [])
    custom_policy_attachments = optional(list(string), [])
    inline_policies          = optional(map(string), {})
    create_access_key        = optional(bool, false)
    tags                     = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}