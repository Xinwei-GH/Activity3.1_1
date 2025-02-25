module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  # VPC Basic Details
  name            = "${local.name}-vpc"
  cidr            = var.vpc_cidr_block
  azs             = var.vpc_availability_zones
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets

  # Database Subnets
  database_subnets                   = var.vpc_database_subnets
  create_database_subnet_group       = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Internet Gateway Tags
  igw_tags = {
    Name = "${local.name}-igw"
  }

  tags     = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
  }

  private_subnet_tags = {
    Type = "Private Subnets"
  }

  database_subnet_tags = {
    Type = "Private Database Subnets"
  }
}

# NAT Gateways
# Remove below code if NAT Gateways are enabled in the module

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip" {
  for_each = { for idx, az in var.vpc_availability_zones : idx => az }
  tags = {
    Name = "${local.name}-eip-${each.value}"
  }
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each      = { for idx, az in var.vpc_availability_zones : idx => az }
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = module.vpc.public_subnets[each.key]
  tags = {
    Name        = "${local.name}-nat-${each.value}"
    Environment = local.environment
  }
}

# Fetch Private Route Tables for Each Private Subnet
data "aws_route_table" "private" {
  count = length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0
  subnet_id = var.vpc_private_subnets[count.index]
}

resource "aws_route" "private_routes" {
  count = length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0

  route_table_id         = length(data.aws_route_table.private) > count.index ? data.aws_route_table.private[count.index].id : null
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateways[count.index].id
}
