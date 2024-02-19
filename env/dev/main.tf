# Define the required Terraform version and AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

/* 
Configure the AWS provider with the region 
were the resources will be created 
*/
provider "aws" {
  region = "us-east-1" #
}

# Module instantiation for creating a VPC
module "vpc" {
  source               = "../../modules/vpc"          # Path to the VPC child module
  cidr_block           = "10.0.0.0/16"                # Define the CIDR block for the VPC
  region               = "us-east-1"                  # Pass the region to the child module
  availability_zones   = ["us-east-1a", "us-east-1b"] # Specify AZs for subnet deployment
  public_subnet_count  = 2
  private_subnet_count = 2
  data_subnet_count    = 2

  # Define NACL rules for subnets to control traffic flow
  nacl_rules = {
    public = {
      ingress = [
        {
          rule_number = 100
          rule_action = "allow"       # Allow all inbound traffic within the VPC
          protocol    = "-1"          # "-1" represents all protocols
          cidr_block  = "10.0.0.0/16" # CIDR block for allowed traffic
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 100
          rule_action = "allow" # Allow all outbound traffic within the VPC
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ]
    },
    private = {
      ingress = [
        {
          rule_number = 200
          rule_action = "allow"       # Allow all inbound traffic within the VPC
          protocol    = "-1"          # "-1" represents all protocols
          cidr_block  = "10.0.0.0/16" # CIDR block for allowed traffic
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 200
          rule_action = "allow" # Allow all outbound traffic within the VPC
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ]
    },
    data = {
      ingress = [
        {
          rule_number = 300
          rule_action = "allow" # Allow all inbound traffic within the VPC
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 300
          rule_action = "allow" # Allow all outbound traffic within the VPC
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ]
    }
  }
}
