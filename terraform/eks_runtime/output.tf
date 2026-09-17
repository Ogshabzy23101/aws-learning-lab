output "nat_gateway_id" {
  value = aws_nat_gateway.devops_lab_natgateway.id
}

output "nat_eip" {
  value = aws_eip.nat.public_ip
}

output "node_group_name" {
  value = aws_eks_node_group.devops_lab_ng.id
}