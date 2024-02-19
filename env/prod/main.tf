terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Specifies the use of the AWS provider from HashiCorp
      version = "~> 5.0"         # Pins the provider version to ensure compatibility
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Defines the AWS region where resources will be deployed
}

module "vpc_prod" {
  source                = "../../modules/vpc"  # Path to the child module
  region                = "us-east-1"          # Passes the region to the child module
  cidr_block            = "10.0.0.0/16"        # CIDR block for the VPC
  
  # Specifies the availability zones to use for subnet deployment
  availability_zones    = ["us-east-1a", "us-east-1b"]
  
  # Configures the number of subnets of each type to create
  public_subnet_count   = 2
  private_subnet_count  = 2
  data_subnet_count     = 2
  
  # Defines NACL rules for each subnet type
  nacl_rules = {
    public = {
      ingress = [
        {
          rule_number = 100, 
          rule_action = "allow", 
          protocol = "tcp", 
          cidr_block = "0.0.0.0/0",  # Allows inbound HTTP traffic from anywhere
          from_port = 80, 
          to_port = 80
        }
      ],
      egress = [
        {
          rule_number = 100, 
          rule_action = "allow", 
          protocol = "tcp", 
          cidr_block = "10.0.2.0/24",  # Allows outbound traffic to private subnets on port 8080
          from_port = 8080, 
          to_port = 8080 
        }
      ]
    },
    private = {
      ingress = [
        {
          rule_number = 200, 
          rule_action = "allow", 
          protocol = "tcp", 
          cidr_block = "10.0.1.0/24",  # Allows inbound traffic from public subnets on port 8080
          from_port = 8080, 
          to_port = 8080 
        }
      ],
      egress = [
        {
          rule_number = 200, 
          rule_action = "allow", 
          protocol = "tcp", 
          cidr_block = "10.0.3.0/24",  # Allows outbound traffic to data subnets on port 3306
          from_port = 3306, 
          to_port = 3306 
        }
      ]
    },
    data = {
      ingress = [
        {
          rule_number = 300, 
          rule_action = "allow", 
          protocol = "tcp", 
          cidr_block = "10.0.2.0/24",  # Allows inbound traffic from private subnets on port 3306
          from_port = 3306, 
          to_port = 3306 
        }
      ],
      egress = []
    }
  }
}
