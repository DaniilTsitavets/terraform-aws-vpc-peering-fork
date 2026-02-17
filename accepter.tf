#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Identity & Region
#-----------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "accepter" {
  provider = aws.accepter
}

data "aws_region" "accepter" {
  provider = aws.accepter
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - VPC
#-----------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "accepter" {
  provider = aws.accepter
  id       = var.accepter_vpc_id
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Subnets
#-----------------------------------------------------------------------------------------------------------------------
data "aws_subnets" "accepter" {
  provider = aws.accepter

  filter {
    name   = "vpc-id"
    values = [var.accepter_vpc_id]
  }
}

# Details for explicitly specified subnets only
data "aws_subnet" "accepter" {
  count    = length(var.accepter_subnet_ids)
  provider = aws.accepter
  id       = var.accepter_subnet_ids[count.index]
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Route Tables
#-----------------------------------------------------------------------------------------------------------------------

# Main route table (fallback)
data "aws_route_table" "accepter_main" {
  provider = aws.accepter
  vpc_id   = var.accepter_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Route tables associated with each subnet
data "aws_route_tables" "accepter" {
  for_each = { for subnet in data.aws_subnets.accepter.ids : subnet => subnet }
  provider = aws.accepter
  vpc_id   = var.accepter_vpc_id

  filter {
    name   = "association.subnet-id"
    values = [each.key]
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Locals
#-----------------------------------------------------------------------------------------------------------------------

locals {
  # Map each subnet to its route table, fallback to main route table
  accepter_subnet_route_table_map = {
    for subnet in data.aws_subnets.accepter.ids :
    subnet => concat(
      data.aws_route_tables.accepter[subnet].ids,
      [data.aws_route_table.accepter_main.id]
    )[0]
  }

  # If specific subnets provided - use only their route tables
  # Otherwise use all route tables in VPC
  accepter_route_table_ids = length(var.accepter_subnet_ids) == 0 ? distinct(values(local.accepter_subnet_route_table_map)) : distinct([
    for subnet_id in var.accepter_subnet_ids : local.accepter_subnet_route_table_map[subnet_id]
  ])

  accepter_route_table_ids_final = length(var.accepter_route_table_ids) == 0 ? local.accepter_route_table_ids : var.accepter_route_table_ids

  # Destination CIDRs for accepter (= CIDRs of requester VPC)
  # If specific requester subnets provided - route only to those subnets
  # Otherwise route to entire requester VPC CIDR
  accepter_dest_cidrs = length(var.requester_subnet_ids) == 0 ? toset([data.aws_vpc.requester.cidr_block]) : toset(data.aws_subnet.requester[*].cidr_block)

  # Associated CIDR blocks of requester VPC (secondary CIDRs)
  accepter_associated_dest_cidrs = toset([
    for assoc in data.aws_vpc.requester.cidr_block_associations : assoc.cidr_block
  ])

  accepter_routes = [
    for pair in setproduct(local.accepter_route_table_ids_final, local.accepter_dest_cidrs) : {
      route_table_id = pair[0]
      cidr_block     = pair[1]
    }
  ]

  # Routes from accepter to requester associated CIDRs
  accepter_associated_routes = [
    for pair in setproduct(local.accepter_route_table_ids_final, local.accepter_associated_dest_cidrs) : {
      route_table_id = pair[0]
      cidr_block     = pair[1]
    }
  ]
}
