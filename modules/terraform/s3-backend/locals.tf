locals {
  # Use consistent naming with root.hcl
  account_name = var.context.aws_account_name != "" ? var.context.aws_account_name : "production"
  account_id   = var.context.aws_account_id != "" ? var.context.aws_account_id : ""
  
  # Bucket naming consistent with root.hcl: terraform-state-${account_name}-${account_id}
  bucket_name = local.account_id != "" ? "terraform-state-${local.account_name}-${local.account_id}" : "terraform-state-${local.account_name}"
}