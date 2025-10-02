stack {
  name        = "roles"
  description = "roles"
  after       = ["/iam/users"]
  id          = "06de8037-4a29-4f69-99ab-9ee6f1546859"
  tags        = ["component.iam", "scope.global"]
}
