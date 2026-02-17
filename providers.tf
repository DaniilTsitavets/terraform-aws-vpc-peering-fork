provider "aws" {
  alias  = "requester"
  region = var.requester_region

  dynamic "assume_role" {
    for_each = var.requester_aws_assume_role_arn != null ? [1] : []
    content {
      role_arn = var.requester_aws_assume_role_arn
    }
  }
}

provider "aws" {
  alias  = "accepter"
  region = var.accepter_region

  dynamic "assume_role" {
    for_each = var.accepter_aws_assume_role_arn != null ? [1] : []
    content {
      role_arn = var.accepter_aws_assume_role_arn
    }
  }
}
