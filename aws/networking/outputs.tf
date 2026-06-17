output "vpc_id" {
  description = "Recorded VPC resource ID if this documentation module were evaluated."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Recorded public subnet resource IDs if this documentation module were evaluated."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Recorded private subnet resource IDs if this documentation module were evaluated."
  value       = [for subnet in aws_subnet.private : subnet.id]
}
