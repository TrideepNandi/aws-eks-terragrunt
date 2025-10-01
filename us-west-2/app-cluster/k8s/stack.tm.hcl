stack {
  name        = "k8s"
  description = "k8s"
  after       = ["/s3-backend", "/us-west-2/app-cluster/networking"]
  id          = "f5a74956-1f88-422f-a32d-f90312f0e4ef"
  tags        = ["component.eks", "region.us-west-2", "cluster.app-cluster"]
}
