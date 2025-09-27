variable "context" {
  description = "Context variables"
  type = object({
    aws_account_name = optional(string, "")
    aws_account_id   = optional(string, "")
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