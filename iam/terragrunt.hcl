include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Deploy users first, then roles
dependencies {
  paths = ["./users"]
}