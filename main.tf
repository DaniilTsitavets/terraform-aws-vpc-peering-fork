locals {
  same_region  = data.aws_region.requester.id == data.aws_region.accepter.id
  same_account = data.aws_caller_identity.requester.account_id == data.aws_caller_identity.accepter.account_id

  create_requester_routes          = var.from_requester && !var.from_requester_associated
  create_requester_associated      = var.from_requester && var.from_requester_associated
  create_accepter_routes           = var.from_accepter && !var.from_accepter_associated
  create_accepter_associated       = var.from_accepter && var.from_accepter_associated
}

#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "this" {
  provider = aws.requester

  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = data.aws_caller_identity.accepter.account_id
  peer_region   = data.aws_region.accepter.id
  auto_accept   = false

  tags = merge(
    var.tags,
    { "Name" = var.name },
    { "Side" = local.same_account && local.same_region ? "Both" : "Requester" }
  )

  timeouts {
    create = "15m"
    delete = "15m"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection Accepter
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_peering_connection_accepter" "this" {
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = var.auto_accept

  tags = merge(
    var.tags,
    { "Name" = var.name },
    { "Side" = local.same_account && local.same_region ? "Both" : "Accepter" }
  )
}

#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection Options - Requester
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "requester" {
  provider = aws.requester

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  requester {
    allow_remote_vpc_dns_resolution = var.requester_allow_remote_vpc_dns_resolution
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection Options - Accepter
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "accepter" {
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  accepter {
    allow_remote_vpc_dns_resolution = var.accepter_allow_remote_vpc_dns_resolution
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Routes - Requester to Accepter
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_route" "requester" {
  count    = local.create_requester_routes ? length(local.requester_routes) : 0
  provider = aws.requester

  route_table_id            = local.requester_routes[count.index].route_table_id
  destination_cidr_block    = local.requester_routes[count.index].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  depends_on = [
    aws_vpc_peering_connection_accepter.this
  ]

  timeouts {
    create = var.route_timeouts.create
    delete = var.route_timeouts.delete
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Routes - Requester to Accepter (Associated CIDRs)
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_route" "requester_associated" {
  count    = local.create_requester_associated ? length(local.requester_associated_routes) : 0
  provider = aws.requester

  route_table_id            = local.requester_associated_routes[count.index].route_table_id
  destination_cidr_block    = local.requester_associated_routes[count.index].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  depends_on = [
    aws_vpc_peering_connection_accepter.this
  ]

  timeouts {
    create = var.route_timeouts.create
    delete = var.route_timeouts.delete
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Routes - Accepter to Requester
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_route" "accepter" {
  count    = local.create_accepter_routes ? length(local.accepter_routes) : 0
  provider = aws.accepter

  route_table_id            = local.accepter_routes[count.index].route_table_id
  destination_cidr_block    = local.accepter_routes[count.index].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  depends_on = [
    aws_vpc_peering_connection_accepter.this
  ]

  timeouts {
    create = var.route_timeouts.create
    delete = var.route_timeouts.delete
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Routes - Accepter to Requester (Associated CIDRs)
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_route" "accepter_associated" {
  count    = local.create_accepter_associated ? length(local.accepter_associated_routes) : 0
  provider = aws.accepter

  route_table_id            = local.accepter_associated_routes[count.index].route_table_id
  destination_cidr_block    = local.accepter_associated_routes[count.index].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  depends_on = [
    aws_vpc_peering_connection_accepter.this
  ]

  timeouts {
    create = var.route_timeouts.create
    delete = var.route_timeouts.delete
  }
}
