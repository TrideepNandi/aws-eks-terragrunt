# VPC configuration for US-East-1 Management Cluster
locals {
  vpc_config = {
    cidr               = "10.10.0.0/16"  # Management cluster gets 10.10.x.x
    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    map_public_ip_on_launch = true

    public_subnets = [
      "10.10.0.0/26",
      "10.10.0.64/26",
      "10.10.0.128/26",
    ]

    private_subnets = [
      "10.10.8.0/21",
      "10.10.16.0/21",
      "10.10.24.0/21",
    ]

    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
    }

    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
    }

    tags = {
      Purpose = "Management Cluster Network"
      Workload = "Platform Tools"
    }
  }
}