#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection
#-----------------------------------------------------------------------------------------------------------------------

output "id" {
  description = "VPC peering connection ID"
  value       = aws_vpc_peering_connection.this.id
}

output "accept_status" {
  description = "Status of the VPC peering connection"
  value       = aws_vpc_peering_connection_accepter.this.accept_status
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester
#-----------------------------------------------------------------------------------------------------------------------

output "requester_account_id" {
  description = "Requester AWS account ID"
  value       = data.aws_caller_identity.requester.account_id
}

output "requester_region" {
  description = "Requester AWS region"
  value       = data.aws_region.requester.id
}

output "requester_vpc_id" {
  description = "Requester VPC ID"
  value       = data.aws_vpc.requester.id
}

output "requester_cidr_block" {
  description = "Requester VPC CIDR block"
  value       = data.aws_vpc.requester.cidr_block
}

output "requester_route_table_ids" {
  description = "Requester route table IDs used for peering routes"
  value       = local.requester_route_table_ids_final
}

output "requester_subnet_route_table_map" {
  description = "Map of requester subnet IDs to route table IDs"
  value       = local.requester_subnet_route_table_map
}

################################################################################
# Accepter
################################################################################

output "accepter_account_id" {
  description = "Accepter AWS account ID"
  value       = data.aws_caller_identity.accepter.account_id
}

output "accepter_region" {
  description = "Accepter AWS region"
  value       = data.aws_region.accepter.id
}

output "accepter_vpc_id" {
  description = "Accepter VPC ID"
  value       = data.aws_vpc.accepter.id
}

output "accepter_cidr_block" {
  description = "Accepter VPC CIDR block"
  value       = data.aws_vpc.accepter.cidr_block
}

output "accepter_route_table_ids" {
  description = "Accepter route table IDs used for peering routes"
  value       = local.accepter_route_table_ids_final
}

output "accepter_subnet_route_table_map" {
  description = "Map of accepter subnet IDs to route table IDs"
  value       = local.accepter_subnet_route_table_map
}
