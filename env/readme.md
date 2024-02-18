
### Parent Module (`/env` directory)


# Parent Modules for VPC Deployment

## Overview

The parent modules located in this directory (`dev` and `prod`) are designed to utilize the child VPC module to deploy environment-specific VPC configurations. They demonstrate how to apply different settings for development and production environments using the same underlying resources.

## Configuration

Each environment module requires certain variables to be set for customization. These include the VPC CIDR block, the number of subnets, NACL rules, and more. These variables are passed to the child VPC module.

## Provider Credentials

Before applying the configurations, ensure your AWS credentials are configured. This can typically be done by setting up the AWS CLI or by exporting your credentials as environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`).

## Applying the Configuration

Navigate to the desired environment directory (`dev` or `prod`) and follow these steps:

**Initialize Terraform:**

```bash
terraform init
terraform plan
terraform apply
```