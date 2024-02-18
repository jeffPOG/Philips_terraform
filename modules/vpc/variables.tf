variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "region" {
  description = "The AWS region in which to deploy the VPC resources"
  type        = string
}


variable "availability_zones" {
  description = "List of availability zones to deploy subnets"
  type        = list(string)
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "data_subnet_count" {
  description = "Number of data subnets to create"
  type        = number
  default     = 2
}

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