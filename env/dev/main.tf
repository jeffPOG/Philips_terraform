terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source               = "../../modules/vpc"
  cidr_block           = "10.0.0.0/16"
  region               = "us-east-1"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_count  = 2
  private_subnet_count = 2
  data_subnet_count    = 2
  nacl_rules = {
    public = {
      ingress = [
        {
          rule_number = 100
          rule_action = "allow"
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 100
          rule_action = "allow"
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
          rule_action = "allow"
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 200
          rule_action = "allow"
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
          rule_action = "allow"
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ],
      egress = [
        {
          rule_number = 300
          rule_action = "allow"
          protocol    = "-1"
          cidr_block  = "10.0.0.0/16"
          from_port   = 0
          to_port     = 0
        }
      ]
    }
  }
}
