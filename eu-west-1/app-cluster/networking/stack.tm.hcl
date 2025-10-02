stack {
  name        = "networking"
  description = "networking"
  after       = ["/s3-backend"]
  id          = "efcca515-8df3-4570-b4db-e0aa52726151"
  tags        = ["component.networking", "region.eu-west-1", "cluster.app-cluster"]
}
