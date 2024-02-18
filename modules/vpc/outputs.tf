output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "data_subnet_ids" {
  value = aws_subnet.data.*.id
}
