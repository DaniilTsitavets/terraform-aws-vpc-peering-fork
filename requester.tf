#-----------------------------------------------------------------------------------------------------------------------
# Requester - Identity & Region
#-----------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "requester" {
  provider = aws.requester
}

data "aws_region" "requester" {
  provider = aws.requester
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - VPC
#-----------------------------------------------------------------------------------------------------------------------
data "aws_vpc" "requester" {
  provider = aws.requester
  id       = var.requester_vpc_id
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - Subnets
#-----------------------------------------------------------------------------------------------------------------------
data "aws_subnets" "requester" {
  provider = aws.requester

  filter {
    name   = "vpc-id"
    values = [var.requester_vpc_id]
  }
}

# Details for explicitly specified subnets only
data "aws_subnet" "requester" {
  count    = length(var.requester_subnet_ids)
  provider = aws.requester
  id       = var.requester_subnet_ids[count.index]
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - Route Tables
#-----------------------------------------------------------------------------------------------------------------------
# Main route table (fallback)
data "aws_route_table" "requester_main" {
  provider = aws.requester
  vpc_id   = var.requester_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Route tables associated with each subnet
data "aws_route_tables" "requester" {
  for_each = { for subnet in data.aws_subnets.requester.ids : subnet => subnet }
  provider = aws.requester
  vpc_id   = var.requester_vpc_id

  filter {
    name   = "association.subnet-id"
    values = [each.key]
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - Locals
#-----------------------------------------------------------------------------------------------------------------------
locals {
  # Map each subnet to its route table, fallback to main route table
  requester_subnet_route_table_map = {
    for subnet in data.aws_subnets.requester.ids :
    subnet => concat(
      data.aws_route_tables.requester[subnet].ids,
      [data.aws_route_table.requester_main.id]
    )[0]
  }

  # If specific subnets provided - use only their route tables
  # Otherwise use all route tables in VPC
  requester_route_table_ids = length(var.requester_subnet_ids) == 0 ? distinct(values(local.requester_subnet_route_table_map)) : distinct([
    for subnet_id in var.requester_subnet_ids : local.requester_subnet_route_table_map[subnet_id]
  ])

  requester_route_table_ids_final = length(var.requester_route_table_ids) == 0 ? local.requester_route_table_ids : var.requester_route_table_ids

  # Destination CIDRs for requester (= CIDRs of accepter VPC)
  # If specific accepter subnets provided - route only to those subnets
  # Otherwise route to entire accepter VPC CIDR
  requester_dest_cidrs = length(var.accepter_subnet_ids) == 0 ? toset([data.aws_vpc.accepter.cidr_block]) : toset(data.aws_subnet.accepter[*].cidr_block)

  # Associated CIDR blocks of accepter VPC (secondary CIDRs)
  requester_associated_dest_cidrs = toset([
    for assoc in data.aws_vpc.accepter.cidr_block_associations : assoc.cidr_block
  ])

  requester_routes = [
    for pair in setproduct(local.requester_route_table_ids_final, local.requester_dest_cidrs) : {
      route_table_id = pair[0]
      cidr_block     = pair[1]
    }
  ]

  # Routes from requester to accepter associated CIDRs
  requester_associated_routes = [
    for pair in setproduct(local.requester_route_table_ids_final, local.requester_associated_dest_cidrs) : {
      route_table_id = pair[0]
      cidr_block     = pair[1]
    }
  ]
}
