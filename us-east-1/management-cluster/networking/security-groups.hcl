# Security Groups configuration for US-East-1 Management Cluster
locals {
  security_groups_config = {
    # Management EKS nodes
    eks_nodes = {
      description = "Security group for Management EKS worker nodes"
      ingress_rules = [
        {
          description = "Allow all traffic from self"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          self        = true
        },
        {
          description = "Allow HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "Allow HTTP from anywhere"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "Allow SSH from VPC"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["10.10.0.0/16"]
        },
        {
          description = "Allow access from app clusters for monitoring"
          from_port   = 9090
          to_port     = 9090
          protocol    = "tcp"
          cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Purpose = "Management-EKS-Nodes"
      }
    }

    # Monitoring security group
    monitoring = {
      description = "Security group for monitoring tools (Prometheus, Grafana)"
      ingress_rules = [
        {
          description = "Allow Grafana access"
          from_port   = 3000
          to_port     = 3000
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "Allow Prometheus access"
          from_port   = 9090
          to_port     = 9090
          protocol    = "tcp"
          cidr_blocks = ["10.10.0.0/16"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Purpose = "Monitoring"
      }
    }
  }
}