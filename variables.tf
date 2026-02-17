#-----------------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name to be used on all resources"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

#-----------------------------------------------------------------------------------------------------------------------
# VPC Peering Connection
#-----------------------------------------------------------------------------------------------------------------------

variable "auto_accept" {
  description = "Automatically accept the peering connection"
  type        = bool
  default     = true
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - Provider Configuration
#-----------------------------------------------------------------------------------------------------------------------

variable "requester_region" {
  description = "Requester AWS region"
  type        = string
}

variable "requester_aws_assume_role_arn" {
  description = "ARN of IAM role to assume in requester account. If not set, default provider credentials will be used"
  type        = string
  default     = null
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - VPC Configuration
#-----------------------------------------------------------------------------------------------------------------------

variable "requester_vpc_id" {
  description = "Requester VPC ID"
  type        = string
}

variable "requester_subnet_ids" {
  description = "List of specific subnet IDs in requester VPC to route traffic to. If empty, routes will be created for entire VPC CIDR"
  type        = list(string)
  default     = []
}

variable "requester_route_table_ids" {
  description = "Explicit list of route table IDs in requester VPC. If empty, route tables will be auto-discovered from subnets"
  type        = list(string)
  default     = []
}

variable "requester_allow_remote_vpc_dns_resolution" {
  description = "Allow requester VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the accepter VPC"
  type        = bool
  default     = true
}

#-----------------------------------------------------------------------------------------------------------------------
# Requester - Traffic Flow
#-----------------------------------------------------------------------------------------------------------------------

variable "from_requester" {
  description = "If traffic from requester VPC to accepter VPC should be allowed"
  type        = bool
  default     = true
}

variable "from_requester_associated" {
  description = "If routes for associated CIDRs (secondary CIDRs) from requester VPC should be created"
  type        = bool
  default     = false
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Provider Configuration
#-----------------------------------------------------------------------------------------------------------------------

variable "accepter_region" {
  description = "Accepter AWS region"
  type        = string
}

variable "accepter_aws_assume_role_arn" {
  description = "ARN of IAM role to assume in accepter account. If not set, default provider credentials will be used"
  type        = string
  default     = null
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - VPC Configuration
#-----------------------------------------------------------------------------------------------------------------------

variable "accepter_vpc_id" {
  description = "Accepter VPC ID"
  type        = string
}

variable "accepter_subnet_ids" {
  description = "List of specific subnet IDs in accepter VPC to route traffic to. If empty, routes will be created for entire VPC CIDR"
  type        = list(string)
  default     = []
}

variable "accepter_route_table_ids" {
  description = "Explicit list of route table IDs in accepter VPC. If empty, route tables will be auto-discovered from subnets"
  type        = list(string)
  default     = []
}

variable "accepter_allow_remote_vpc_dns_resolution" {
  description = "Allow accepter VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the requester VPC"
  type        = bool
  default     = true
}

#-----------------------------------------------------------------------------------------------------------------------
# Accepter - Traffic Flow
#-----------------------------------------------------------------------------------------------------------------------

variable "from_accepter" {
  description = "If traffic from accepter VPC to requester VPC should be allowed"
  type        = bool
  default     = true
}

variable "from_accepter_associated" {
  description = "If routes for associated CIDRs (secondary CIDRs) from accepter VPC should be created"
  type        = bool
  default     = false
}

#-----------------------------------------------------------------------------------------------------------------------
# Timeouts
#-----------------------------------------------------------------------------------------------------------------------

variable "route_timeouts" {
  description = "Timeouts for route creation and deletion"
  type = object({
    create = optional(string, "5m")
    delete = optional(string, "5m")
  })
  default = {}
}
