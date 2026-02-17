# 🔗 VPC Peering Cross-Account Module 🔗

* All usage examples are in the root `examples` folder. ***Keep in mind they show implementation with `Terragrunt`.***
* This module can provision the following resources:
    * `VPC Peering Connection` (requester side);
    * `VPC Peering Connection Accepter` (accepter side);
    * `VPC Peering Connection Options` (DNS resolution for both sides);
    * `Routes` in both VPCs (auto-discovered from subnets and route tables);

# 🛩️ Useful information 🛩️

* The module supports **any type of VPC peering**: cross-account, same-account, cross-region, same-region. However, it has only been **tested with cross-account same-region** configuration. Use other combinations at your own risk.
* The module provisions providers internally, so `requester_aws_assume_role_arn` and `accepter_aws_assume_role_arn` can be passed directly as inputs — no need for `generate "providers"` in Terragrunt.
* Route tables are **auto-discovered** from subnets. You can also pass specific subnet IDs or route table IDs to limit the scope of routes created.

# 🔐 IAM Requirements 🔐

## Requester Account (`XXXXXXXX`) — Optional

> **`requester_aws_assume_role_arn` is optional.** If Terraform runs under an IAM user or role that already has sufficient EC2 permissions in the requester account (e.g. `AdministratorAccess` or a custom policy), you do **not** need to create a separate role — just omit this variable and the provider will use your current credentials directly.

A separate requester role is only needed if:
* Terraform runs under a CI/CD identity that doesn't have EC2 peering permissions yet, and you want to scope permissions via assume role.

If you do need a requester role, here are the required policies:

### Role Trust Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::XXXXXXXX:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
```

### Role Permission Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateRoute",
        "ec2:DeleteRoute"
      ],
      "Resource": "arn:aws:ec2:*:XXXXXXXX:route-table/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcPeeringConnections",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcPeeringConnectionOptions",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeRouteTables"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AcceptVpcPeeringConnection",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:CreateVpcPeeringConnection",
        "ec2:RejectVpcPeeringConnection"
      ],
      "Resource": [
        "arn:aws:ec2:*:XXXXXXXX:vpc-peering-connection/*",
        "arn:aws:ec2:*:XXXXXXXX:vpc/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags",
        "ec2:CreateTags"
      ],
      "Resource": "arn:aws:ec2:*:XXXXXXXX:vpc-peering-connection/*"
    }
  ]
}
```

> Replace `XXXXXXXX` with the **requester** account ID.

---

## Accepter Account (`YYYYYYYY`) — Required

Since Terraform runs in the requester account, it has no access to the accepter account by default. You **must** create an IAM role in the accepter account and pass its ARN as `accepter_aws_assume_role_arn`.

### Role Trust Policy
Allow the requester account to assume this role:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::XXXXXXXX:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
```

> Replace `XXXXXXXX` with the **requester** account ID.

### Role Permission Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateRoute",
        "ec2:DeleteRoute"
      ],
      "Resource": "arn:aws:ec2:*:YYYYYYYY:route-table/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcPeeringConnections",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcPeeringConnectionOptions",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeRouteTables"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AcceptVpcPeeringConnection",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:CreateVpcPeeringConnection",
        "ec2:RejectVpcPeeringConnection"
      ],
      "Resource": [
        "arn:aws:ec2:*:YYYYYYYY:vpc-peering-connection/*",
        "arn:aws:ec2:*:YYYYYYYY:vpc/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags",
        "ec2:CreateTags"
      ],
      "Resource": "arn:aws:ec2:*:YYYYYYYY:vpc-peering-connection/*"
    }
  ]
}
```

> Replace `YYYYYYYY` with the **accepter** account ID.

---

# 🚀 Usage Examples (Terragrunt) 🚀

## Without requester role (most common case)
If you run Terraform under a user/role that already has access to the requester account:

```hcl
# terragrunt.hcl
inputs = {
  name = "prod-to-shared"

  # Requester (Account A) - no assume_role_arn needed!
  requester_region = "us-east-1"
  requester_vpc_id = dependency.vpc.outputs.vpc_id

  # Accepter (Account B) - role required, no direct access
  accepter_region              = "us-east-1"
  accepter_aws_assume_role_arn = "arn:aws:iam::222222222222:role/VPCPeeringAccepterRole"
  accepter_vpc_id              = "vpc-0000000000000000"

  auto_accept = true

  tags = {
    Environment = "production"
    ManagedBy   = "terragrunt"
  }
}
```

## With requester role (CI/CD case)
If Terraform runs under a CI/CD identity that assumes a scoped role:

```hcl
# terragrunt.hcl
inputs = {
  name = "prod-to-shared"

  # Requester (Account A) - explicit assume role for CI/CD
  requester_region              = "us-east-1"
  requester_aws_assume_role_arn = "arn:aws:iam::111111111111:role/VPCPeeringRequesterRole"
  requester_vpc_id              = dependency.vpc.outputs.vpc_id

  # Accepter (Account B)
  accepter_region              = "us-east-1"
  accepter_aws_assume_role_arn = "arn:aws:iam::222222222222:role/VPCPeeringAccepterRole"
  accepter_vpc_id              = "vpc-0000000000000000"

  auto_accept = true

  tags = {
    Environment = "production"
    ManagedBy   = "terragrunt"
  }
}
```
