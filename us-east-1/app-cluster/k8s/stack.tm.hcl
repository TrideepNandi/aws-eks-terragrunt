stack {
  name        = "k8s"
  description = "k8s"
  after       = ["/us-east-1/app-cluster/networking"]
  id          = "007d0e21-7e08-4bee-b4a8-747e9cd4c1a6"
  tags        = ["component.eks", "region.us-east-1", "cluster.app-cluster"]
}
