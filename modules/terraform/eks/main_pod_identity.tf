resource "aws_eks_pod_identity_association" "this" {
  for_each = var.eks_pod_identity_association

  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn != "" ? each.value.role_arn : var.iam_assumable_roles[each.value.role_name].arn

  tags = merge(
    {
      Name = "${module.eks.cluster_name}-${each.key}"
    },
    var.context.tags
  )
}