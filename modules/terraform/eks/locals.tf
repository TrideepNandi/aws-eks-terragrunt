locals {
  project_code = lower(replace(var.context.project_code, "-", ""))
  workload     = trimsuffix("${local.project_code}-${var.context.workload_name}", "-")
  eks_name     = "eks-${local.workload}-${var.context.environment_name}-${var.context.aws_region_short}-${var.context.instance_index}"
}