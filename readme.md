# Terraform VPC Deployment Project

## Overview

This project automates the deployment of a highly available and scalable Virtual Private Cloud infrastructure on AWS using Terraform. It is structured into one reusable child module that creates a VPC and two parent modules that leverage this child module to deploy specific configurations for development (`dev`) and production (`prod`) environments.

## Project Structure

- **Parent Modules (`/env/dev` and `/env/prod`):** These modules use the child module to instantiate a VPC with environment-specific settings.
- **Child Module (`/modules/vpc`):** A reusable module responsible for creating the VPC, subnets, route tables, NACLs, and other related resources.

## How It Works

The parent modules (`dev` and `prod`) specify environment-specific configurations such as the number of subnets, NACL rules, and the CIDR blocks. These modules pass variables to the child module, demonstrating the modularity and reusability of Terraform modules for different deployment scenarios.

The child module defines the core resources required for a VPC, including subnets spanning multiple Availability Zones (AZs), route tables, Internet Gateways, NAT Gateways, and Network Access Control Lists (NACLs). It is designed to be flexible and reusable across different environments.

## Getting Started

To use this project, you need to have Terraform installed and configured with your AWS credentials. Clone this repository, navigate to the desired environment within the `env` directory, and apply the Terraform configurations as shown below.

### Prerequisites

- Terraform installed
- AWS account and CLI configured

### Applying a Configuration

1. **Initialize Terraform:**

```bash
terraform init
terraform plan
terraform apply
```