data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.philips_vpc.id]
  }
}

locals {
  tier_nacl_rules = var.nacl_rules
}


resource "aws_vpc" "philips_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.philips_vpc.id

  tags = {
    Name = "philips_vpc_igw"
  }
}

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

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "philips_vpc_nat"
  }
}

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

resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data" {
  count          = var.data_subnet_count
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# public NACL
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "Public NACL"
  }
}

# private NACL
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "private NACL"
  }
}


# data NACL
resource "aws_network_acl" "data" {
  vpc_id = aws_vpc.philips_vpc.id
  tags = {
    Name = "data NACL"
  }
}


resource "aws_network_acl_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  network_acl_id = aws_network_acl.private.id
}

resource "aws_network_acl_association" "data" {
  count          = var.data_subnet_count
  subnet_id      = aws_subnet.data[count.index].id
  network_acl_id = aws_network_acl.data.id
}

resource "aws_network_acl_rule" "public_subnet_egress" {
  for_each      = { for rule in local.tier_nacl_rules["public"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

resource "aws_network_acl_rule" "private_subnet_egress" {
  for_each      = { for rule in local.tier_nacl_rules["private"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

resource "aws_network_acl_rule" "data_subnet_egress" {
  for_each      = { for rule in local.tier_nacl_rules["data"].egress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.data.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = true
}

resource "aws_network_acl_rule" "public_subnet_ingress" {
  for_each      = { for rule in local.tier_nacl_rules["public"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

resource "aws_network_acl_rule" "private_subnet_ingress" {
  for_each      = { for rule in local.tier_nacl_rules["private"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

resource "aws_network_acl_rule" "data_subnet_ingress" {
  for_each      = { for rule in local.tier_nacl_rules["data"].ingress : rule.rule_number => rule }
  network_acl_id = aws_network_acl.data.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.philips_vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.public.id, aws_route_table.private.id] 
  tags = {
    Name = "S3VpcEndpoint"
  }
}

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


resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.philips_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids = tolist(data.aws_subnets.selected.ids)
  security_group_ids = [aws_security_group.ec2_endpoint_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "EC2VpcEndpoint"
  }
}

