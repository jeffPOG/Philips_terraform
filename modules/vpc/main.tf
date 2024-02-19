# Fetches the information of subnets selected based on the VPC ID.
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.philips_vpc.id]
  }
}

# Local variable to hold the dynamically specified NACL rules.
locals {
  tier_nacl_rules = var.nacl_rules
}

# Creates a VPC with DNS support and hostnames enabled.
resource "aws_vpc" "philips_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Creates public subnets with the specified CIDR blocks and availability zones.
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.philips_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true
  tags = {
    Role = "public"
    AZ   = var.availability_zones[count.index]
  }
}

# Creates private subnets similar to public, but these are for internal use within the VPC.
resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.philips_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + 2)
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags = {
    Role = "private"
    AZ   = var.availability_zones[count.index]
  }
}

# Creates data subnets which are typically used for databases or application data layers.
resource "aws_subnet" "data" {
  count             = var.data_subnet_count
  vpc_id            = aws_vpc.philips_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + 4)
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags = {
    Role = "data"
    AZ   = var.availability_zones[count.index]
  }
}

# Attaches an Internet Gateway to the VPC to allow communication between resources in the VPC and the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "philips_vpc_igw"
  }
}

# Defines a route table for public subnets that routes traffic to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.philips_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Associates the public route table with the public subnets.
resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Creates an Elastic IP EIP for the NAT Gateway, allowing instances in the private subnet to initiate outbound internet traffic.
resource "aws_eip" "nat" {
  domain = "vpc"
}

# Deploys a NAT Gateway using the allocated EIP, enabling instances in private subnets to access the internet.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "philips_vpc_nat"
  }
}

# Similar to the public route table, but for private subnets, routing traffic through the NAT Gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.philips_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "Private Route Table"
  }
}

# A route table for data subnets, similar to private, facilitating controlled access to the internet.
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.philips_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "Data Route Table"
  }
}

# Associates private route tables with private subnets, enabling internal network routing.
resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associates data route tables with data subnets, enabling internal network routing for data layers.
resource "aws_route_table_association" "data" {
  count          = var.data_subnet_count
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# Creates a Network ACL for public subnets, specifying access controls for inbound and outbound traffic.
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "Public NACL"
  }
}

# Creates a Network ACL for private subnets, specifying access controls similar to public subnets but for internal use.
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "Private NACL"
  }
}

# Creates a Network ACL for data subnets, focusing on database and application data layers' access controls.
resource "aws_network_acl" "data" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "Data NACL"
  }
}

# Associates the public Network ACL with public subnets to apply the specified access controls.
resource "aws_network_acl_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public.id
}

# Associates the private Network ACL with private subnets to apply the specified access controls.
resource "aws_network_acl_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  network_acl_id = aws_network_acl.private.id
}

# Associates the data Network ACL with data subnets to apply the specified access controls.
resource "aws_network_acl_association" "data" {
  count          = var.data_subnet_count
  subnet_id      = aws_subnet.data[count.index].id
  network_acl_id = aws_network_acl.data.id
}

# Defines NACL rules for egress traffic from public subnets based on specified criteria for dynamic rule application.
resource "aws_network_acl_rule" "public_subnet_egress" {
  for_each       = { for rule in local.tier_nacl_rules["public"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

# Similar to public subnet egress, but defines egress rules for private subnets.
resource "aws_network_acl_rule" "private_subnet_egress" {
  for_each       = { for rule in local.tier_nacl_rules["private"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

# Defines egress rules for data subnets, focusing on data layers' specific traffic patterns and security requirements.
resource "aws_network_acl_rule" "data_subnet_egress" {
  for_each       = { for rule in local.tier_nacl_rules["data"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.data.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

# Defines NACL rules for ingress traffic to public subnets, enhancing security by controlling access based on specific criteria.
resource "aws_network_acl_rule" "public_subnet_ingress" {
  for_each       = { for rule in local.tier_nacl_rules["public"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

# Defines ingress rules for private subnets, focusing on internal connectivity and security between different layers of the application architecture.
resource "aws_network_acl_rule" "private_subnet_ingress" {
  for_each       = { for rule in local.tier_nacl_rules["private"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

# Defines ingress rules for data subnets, ensuring secure and controlled access to data resources within the VPC.
resource "aws_network_acl_rule" "data_subnet_ingress" {
  for_each       = { for rule in local.tier_nacl_rules["data"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.data.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

# Creates a VPC endpoint for Amazon S3, facilitating private connections to S3 services, bypassing the public internet for enhanced security and performance.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.philips_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]
  tags              = { Name = "S3VpcEndpoint" }
}

# Defines a security group for the EC2 VPC Endpoint, specifying rules for inbound and outbound traffic to secure the endpoint.
resource "aws_security_group" "ec2_endpoint_sg" {
  name        = "ec2_endpoint_sg"
  description = "Security Group for EC2 VPC Interface Endpoint"
  vpc_id      = aws_vpc.philips_vpc.id

  # Allow inbound HTTPS from the VPC CIDR
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.philips_vpc.cidr_block]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2EndpointSG"
  }
}

/* 
 Creates a VPC endpoint for Amazon EC2, enabling private connections
 to EC2 services, enhancing security by not exposing traffic to the public 
 internet 
*/
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.philips_vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = tolist(data.aws_subnets.selected.ids)
  security_group_ids  = [aws_security_group.ec2_endpoint_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "EC2VpcEndpoint"
  }
}

