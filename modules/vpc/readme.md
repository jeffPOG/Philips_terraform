# Child Module: VPC

## Overview

This module is designed to automate the creation of a Virtual Private Cloud (VPC) in AWS, including associated resources such as subnets, route tables, Internet Gateways, NAT Gateways, and Network Access Control Lists (NACLs). It offers flexibility and reusability across various environments within AWS.

## Usage

Incorporate this module into your Terraform environment configurations by specifying it as a source in your Terraform files. Pass all required variables to customize the VPC according to your needs.

### Example Usage

```hcl
module "vpc" {
  source = "path/to/modules/vpc"

  cidr_block = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnet_count = 2
  private_subnet_count = 2
  data_subnet_count = 2
  nacl_rules = var.nacl_rules
}
```

### Availiable Variables

- cidr_block: CIDR block for the VPC.
- availability_zones: List of AZs to deploy subnets.
- public_subnet_count: Number of public subnets.
- private_subnet_count: Number of private subnets.
- data_subnet_count: Number of data subnets.
- nacl_rules: Custom NACL rules for each subnet type.

For a complete list of variables, refer to the variables.tf file within this module.