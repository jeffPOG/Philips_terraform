# Outputs the IDs of the created public subnets.
output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

# Outputs the IDs of the created private subnets.
output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

# Outputs the IDs of the created data subnets.
output "data_subnet_ids" {
  value = aws_subnet.data.*.id
}
