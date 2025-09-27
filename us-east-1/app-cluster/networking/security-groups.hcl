# Security Groups configuration for US-East-1 App Cluster
locals {
  security_groups_config = {
    # Default security group for EKS nodes
    eks_nodes = {
      description = "Security group for EKS worker nodes"
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
          cidr_blocks = ["10.1.0.0/16"]
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
        Purpose = "EKS-Nodes"
      }
    }

    # Load balancer security group
    alb = {
      description = "Security group for Application Load Balancer"
      ingress_rules = [
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
        Purpose = "ALB"
      }
    }

    # Database security group
    database = {
      description = "Security group for RDS databases"
      ingress_rules = [
        {
          description = "Allow MySQL/Aurora from VPC"
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          cidr_blocks = ["10.1.0.0/16"]
        },
        {
          description = "Allow PostgreSQL from VPC"
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.1.0.0/16"]
        }
      ]
      egress_rules = []
      tags = {
        Purpose = "Database"
      }
    }
  }
}