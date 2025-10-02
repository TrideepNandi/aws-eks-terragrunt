# VPC configuration for US-East-1 App Cluster
locals {
  vpc_config = {
    cidr               = "10.1.0.0/16"
    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    map_public_ip_on_launch = true

    private_subnets = [
      "10.1.8.0/21",
      "10.1.16.0/21",
      "10.1.24.0/21",
    ]

    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
    }

    tags = {
      Purpose = "Application Cluster Network"
      Workload = "Applications"
    }
  }
}
