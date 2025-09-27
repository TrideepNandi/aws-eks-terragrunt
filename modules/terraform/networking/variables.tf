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
    instance_index = optional(number, 1)
    tags           = optional(map(string), {})
  })
}

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr               = string
    enable_nat_gateway = optional(bool, true)
    single_nat_gateway = optional(bool, false)
    one_nat_gateway_per_az = optional(bool, true)
    
    map_public_ip_on_launch = optional(bool, false)
    
    public_subnets  = list(string)
    private_subnets = list(string)
    
    public_subnet_tags  = optional(map(string), {})
    private_subnet_tags = optional(map(string), {})
    
    tags = optional(map(string), {})
  })
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    description = string
    ingress_rules = list(object({
      description      = string
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string))
      ipv6_cidr_blocks = optional(list(string))
      security_groups  = optional(list(string))
      self             = optional(bool)
    }))
    egress_rules = list(object({
      description      = string
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string))
      ipv6_cidr_blocks = optional(list(string))
      security_groups  = optional(list(string))
      self             = optional(bool)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}