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

  # NAT Gateways - Outbound Communication ( uncomment below if you set "true" for VPC Enable NAT Gateway in variable.tf )
  /*enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway*/

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
  for_each = toset(var.vpc_availability_zones)
  tags = {
    Name = "${local.name}-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each      = toset(var.vpc_availability_zones)
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = element(module.vpc.public_subnets, index(var.vpc_availability_zones, each.key))
  tags = {
    Name        = "${local.name}-nat-${each.key}"
    Environment = local.environment
  }
}

# Fetch Private Route Tables for Each Private Subnet
data "aws_route_table" "private" {
  for_each = toset(module.vpc.private_subnets) # Iterate over private subnets
  subnet_id = each.value                       # Fetch the route table for the subnet
}

# Update Private Routes
resource "aws_route" "private_routes" {
  for_each               = toset(var.vpc_availability_zones)
  route_table_id         = data.aws_route_table.private[element(module.vpc.private_subnets, index(var.vpc_availability_zones, each.key))].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateways[each.key].id
}