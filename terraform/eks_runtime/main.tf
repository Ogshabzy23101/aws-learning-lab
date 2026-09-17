terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "devops-lab-nat-eip"
  }
}

resource "aws_nat_gateway" "devops_lab_natgateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "devops-lab-natgateway"
  }
}

resource "aws_route" "private_route_to_nat" {
  route_table_id         = var.private_route_tb_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.devops_lab_natgateway.id
}



resource "aws_eks_node_group" "devops_lab_ng" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  region          = var.region

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled"        = "true"
    "k8s.io/cluster-autoscaler/devops-lab-eks" = "owned"

  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_route.private_route_to_nat
  ]
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.devops_lab_ng]
}
resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"
  depends_on   = [aws_eks_node_group.devops_lab_ng]
}
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = "arn:aws:iam::384567542379:role/devops-lab-ebsrole"
  }
  depends_on = [aws_eks_node_group.devops_lab_ng]
}

#pod identity for cluster auto scaller
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.cluster_name
  role_arn        = var.cluster_autoscaler_arn
  namespace       = "kube-system"
  service_account = var.service_account
  region          = var.region
}