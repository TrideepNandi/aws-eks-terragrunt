# VPC Outputs
output "vpc" {
  description = "VPC outputs"
  value = {
    vpc_id                = aws_vpc.this.id
    vpc_arn               = aws_vpc.this.arn
    vpc_cidr_block        = aws_vpc.this.cidr_block
    vpc_main_route_table_id = aws_vpc.this.main_route_table_id
    
    # Subnets
    public_subnets        = aws_subnet.public[*].id
    private_subnets       = aws_subnet.private[*].id
    public_subnet_arns    = aws_subnet.public[*].arn
    private_subnet_arns   = aws_subnet.private[*].arn
    
    # Route Tables
    public_route_table_ids  = aws_route_table.public[*].id
    private_route_table_ids = aws_route_table.private[*].id
    
    # Gateways
    internet_gateway_id   = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
    nat_gateway_ids       = aws_nat_gateway.this[*].id
    nat_public_ips        = aws_eip.nat[*].public_ip
    
    # Availability Zones
    azs = local.azs
  }
}

# Security Group Outputs
output "security_groups" {
  description = "Security group outputs"
  value = {
    for k, v in aws_security_group.this : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    for k, v in aws_security_group.this : k => v.id
  }
}

# Debug outputs
output "debug_azs" {
  description = "Available AZs being used"
  value       = local.azs
}

output "debug_public_subnets" {
  description = "Public subnets configuration"
  value       = var.vpc.public_subnets
}

output "debug_private_subnets" {
  description = "Private subnets configuration"
  value       = var.vpc.private_subnets
}

output "debug_counts" {
  description = "Subnet and AZ counts"
  value = {
    azs_count = local.azs_count
    public_subnets_count = local.public_subnets_count
    private_subnets_count = local.private_subnets_count
  }
}

output "debug_vpc_inputs" {
  description = "What we're passing to VPC module"
  value = {
    name = local.vpc_name
    cidr = var.vpc.cidr
    azs = local.azs
    public_subnets = length(var.vpc.public_subnets) > 0 ? var.vpc.public_subnets : []
    private_subnets = length(var.vpc.private_subnets) > 0 ? var.vpc.private_subnets : []
  }
}