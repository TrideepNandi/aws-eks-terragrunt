stack {
  name        = "networking"
  description = "networking"
  after       = ["/s3-backend"]
  id          = "0d6dbb68-9da6-4d37-bddd-0363177b5b3f"
  tags        = ["component.networking", "region.us-west-2", "cluster.app-cluster"]
}
