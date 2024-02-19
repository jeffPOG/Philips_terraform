# Specifies the CIDR block for the VPC to be created.
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

# Defines the AWS region where the VPC and its resources will be deployed.
variable "region" {
  description = "The AWS region in which to deploy the VPC resources"
  type        = string
}

# Lists the availability zones within the specified region where subnets will be created.
variable "availability_zones" {
  description = "List of availability zones to deploy subnets"
  type        = list(string)
}

# Sets the number of public subnets to be created within the VPC.
variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

# Sets the number of private subnets to be created within the VPC.
variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

# Sets the number of data subnets to be created within the VPC.
variable "data_subnet_count" {
  description = "Number of data subnets to create"
  type        = number
  default     = 2
}

# Defines the Network ACL rules for each type of subnet in the VPC.
variable "nacl_rules" {
  description = "A map of NACL rules for each subnet type"
  type = map(object({
    ingress = list(object({
      rule_number = number
      rule_action = string
      protocol    = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))
    egress = list(object({
      rule_number = number
      rule_action = string
      protocol    = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))
  }))
}
