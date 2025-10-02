stack {
  name        = "k8s"
  description = "k8s"
  after       = ["/eu-west-1/app-cluster/networking", "/s3-backend"]
  id          = "43b3e3f7-4009-48d4-ac0b-5dc41df645fa"
  tags        = ["component.eks", "region.us-west-1", "cluster.app-cluster"]
}
