stack {
  name        = "networking"
  description = "networking"
  after       = ["/s3-backend"]
  id          = "41b8e3bc-0c1c-4707-a8df-d2373de6f5c6"
  tags        = ["component.networking", "region.us-east-1", "cluster.app-cluster"]
}
