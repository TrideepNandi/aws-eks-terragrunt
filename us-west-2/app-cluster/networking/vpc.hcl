# VPC configuration for US-West-2 App Cluster
locals {
  vpc_config = {
    cidr               = "10.2.0.0/16"
    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    map_public_ip_on_launch = true

    public_subnets = [
      "10.2.0.0/26",
      "10.2.0.64/26",
      "10.2.0.128/26",
    ]

    private_subnets = [
      "10.2.8.0/21",
      "10.2.16.0/21",
      "10.2.24.0/21",
    ]

    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
    }

    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
    }

    tags = {
      Purpose = "Application Cluster Network"
      Workload = "Applications"
    }
  }
}