# Local values for naming
locals {
  vpc_name = "${var.context.project_code}-${var.context.aws_region_short}-${var.context.workload_name}-vpc"
  # Use exactly 3 AZs to match the subnet configuration
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Generate name prefix for security groups
  sg_name_prefix = "${var.context.project_code}-${var.context.aws_region_short}-${var.context.workload_name}-"
  
  # Debug values
  public_subnets_count = length(var.vpc.public_subnets)
  private_subnets_count = length(var.vpc.private_subnets)
  azs_count = length(local.azs)
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Validation to ensure we have enough AZs
resource "null_resource" "validate_azs" {
  count = length(data.aws_availability_zones.available.names) >= 3 ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'Error: Not enough availability zones available in region ${var.context.aws_region}' && exit 1"
  }
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.context.tags,
    var.vpc.tags,
    {
      Name = local.vpc_name
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count = length(var.vpc.public_subnets) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.context.tags,
    {
      Name = "${local.vpc_name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.vpc.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.vpc.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.vpc.map_public_ip_on_launch

  tags = merge(
    var.context.tags,
    var.vpc.public_subnet_tags,
    {
      Name = "${local.vpc_name}-public-${local.azs[count.index]}"
      Type = "Public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.vpc.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vpc.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.context.tags,
    var.vpc.private_subnet_tags,
    {
      Name = "${local.vpc_name}-private-${local.azs[count.index]}"
      Type = "Private"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.vpc.enable_nat_gateway ? (var.vpc.single_nat_gateway ? 1 : length(var.vpc.public_subnets)) : 0

  domain = "vpc"

  tags = merge(
    var.context.tags,
    {
      Name = "${local.vpc_name}-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  count = var.vpc.enable_nat_gateway ? (var.vpc.single_nat_gateway ? 1 : length(var.vpc.public_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.vpc.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    var.context.tags,
    {
      Name = "${local.vpc_name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# Public Route Table
resource "aws_route_table" "public" {
  count = length(var.vpc.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(
    var.context.tags,
    {
      Name = "${local.vpc_name}-public-rt"
    }
  )
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = var.vpc.enable_nat_gateway ? (var.vpc.single_nat_gateway ? 1 : length(var.vpc.private_subnets)) : length(var.vpc.private_subnets)

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.vpc.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.vpc.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(
    var.context.tags,
    {
      Name = "${local.vpc_name}-private-rt-${count.index + 1}"
    }
  )
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.vpc.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = length(var.vpc.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.vpc.single_nat_gateway ? 0 : count.index].id
}

# Security Groups
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name_prefix = "${local.sg_name_prefix}${each.key}-"
  description = each.value.description
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
    }
  }

  tags = merge(
    {
      Name = "${local.sg_name_prefix}${each.key}"
      Type = "SecurityGroup"
    },
    var.context.tags,
    each.value.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}