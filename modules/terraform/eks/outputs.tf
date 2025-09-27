output "eks" {
  description = "EKS cluster configuration"
  value       = module.eks
}

output "karpenter" {
  description = "Karpenter configuration"
  value       = var.karpenter.create ? module.karpenter[0] : null
}