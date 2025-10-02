stack {
  name        = "networking"
  description = "networking"
  after       = ["/s3-backend"]
  id          = "2d084e90-1f33-4f82-a635-930cee630afa"
  tags        = ["component.networking", "region.us-east-1", "cluster.app-cluster"]
}
