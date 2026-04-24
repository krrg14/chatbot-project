output "cluster_id" {
  value = aws_eks_cluster.chatbot.id
}

output "node_group_id" {
  value = aws_eks_node_group.chatbot_nodes.id
}

output "vpc_id" {
  value = aws_vpc.chatbot_vpc.id
}

output "subnet_id" {
  value = aws_subnet.chatbot_subnet[*].id
}