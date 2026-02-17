# ----------------------------------------------------------------------------------------------------------------------
# Terraform Module Source
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  source = "${dirname(find_in_parent_folders("root.terragrunt.hcl"))}/_catalog/modules//vpc-peering"
}

# ----------------------------------------------------------------------------------------------------------------------
# Local Variables
# ----------------------------------------------------------------------------------------------------------------------
locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  env    = local.environment_vars.locals.environment.short
  prefix = "${local.environment_vars.locals.prefix}-${local.region_vars.locals.aws_region_short}"
  region = local.region_vars.locals.aws_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Dependencies
# ----------------------------------------------------------------------------------------------------------------------
dependency "data" {
  config_path = "${get_terragrunt_dir()}/../../data"
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../vpc"

  mock_outputs = {
    vpc_id = "vpc-11111aa1a111c1a11"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Input Variables
# ----------------------------------------------------------------------------------------------------------------------
inputs = {
  name = "${local.prefix}-peering-${basename(get_terragrunt_dir())}"

  requester_aws_assume_role_arn = "arn:aws:iam::${dependency.data.outputs.account_id}:role/VPCPeeringRequesterRole"
  requester_region              = local.region
  requester_vpc_id              = dependency.vpc.outputs.vpc_id

  accepter_aws_assume_role_arn = "arn:aws:iam::111111111111:role/VPCPeeringAccepterRole"
  accepter_region              = "us-east-1"
  accepter_vpc_id              = "vpc-11a1111a1111aa11a"
}
