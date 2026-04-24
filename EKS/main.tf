resource "aws_vpc" "chatbot_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = { Name = "chatbot_vpc" }
}

resource "aws_subnet" "chatbot_subnet" {
  count      = 2
  vpc_id     = aws_vpc.chatbot_vpc.id
  cidr_block = cidrsubnet(aws_vpc.chatbot_vpc.cidr_block, 8, count.index)

  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = { Name = "chatbot-sub-${count.index}" }
}

resource "aws_internet_gateway" "chatbot_igw" {
  vpc_id = aws_vpc.chatbot_vpc.id

  tags = { Name = "chatbot-igw" }
}

resource "aws_route_table" "chatbot_rt" {
  vpc_id = aws_vpc.chatbot_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chatbot_igw.id
  }

  tags = { Name = "chatbot-rt" }
}

resource "aws_route_table_association" "chatbot_rta" {
  count          = 2
  subnet_id      = aws_subnet.chatbot_subnet[count.index].id
  route_table_id = aws_route_table.chatbot_rt.id
}

resource "aws_security_group" "chatbot_cluster_sg" {
  vpc_id = aws_vpc.chatbot_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "chatbot_cluster_sg" }
}

resource "aws_security_group" "chatbot_nodes_sg" {
  vpc_id = aws_vpc.chatbot_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "chatbot_nodes_sg" }
}

resource "aws_iam_role" "chatbot_cluster_role" {
  name = "chatbot_cluster_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.chatbot_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "chatbot_node_role" {
  name = "chatbot_node_role"

  assume_role_policy = <<EOF
  {
      "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
        "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.chatbot_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.chatbot_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  role       = aws_iam_role.chatbot_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "chatbot" {
  name     = "chatbot_cluster"
  role_arn = aws_iam_role.chatbot_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.chatbot_subnet[*].id
    security_group_ids = [aws_security_group.chatbot_cluster_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

resource "aws_eks_node_group" "chatbot_nodes" {
  cluster_name    = aws_eks_cluster.chatbot.name
  node_group_name = "chatbot-nodes-group"
  node_role_arn   = aws_iam_role.chatbot_node_role.arn

  subnet_ids = aws_subnet.chatbot_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 100
    min_size     = 2
  }

  instance_types = ["m7i-flex.large"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [aws_security_group.chatbot_nodes_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_registry_policy
  ]
}