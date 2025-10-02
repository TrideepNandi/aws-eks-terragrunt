stack {
  name        = "k8s"
  description = "k8s"
  after       = ["/us-east-1/management-cluster/networking"]
  id          = "c9d8917a-48ba-4dc9-a324-3a6dec52e078"
  tags        = ["component.eks", "region.us-east-1", "cluster.management-cluster"]
}
