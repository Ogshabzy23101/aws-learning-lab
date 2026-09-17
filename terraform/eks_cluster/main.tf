resource "aws_eks_cluster" "devops-lab-eks" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.cluster_role
  version  = "1.36"

  vpc_config {
    subnet_ids = var.subnet_ids
  }

}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.devops-lab-eks.name
  addon_name   = "vpc-cni"
  
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.devops-lab-eks.name
  addon_name   = "kube-proxy"
  
}

resource "aws_eks_addon" "pod_id" {
  cluster_name = aws_eks_cluster.devops-lab-eks.name
  addon_name   = "eks-pod-identity-agent"
  
}

resource "aws_eks_access_entry" "dami_admin" {
  cluster_name = aws_eks_cluster.devops-lab-eks.name
  principal_arn = var.dami_user_arn
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "dami_admin" {
cluster_name = aws_eks_cluster.devops-lab-eks.name
principal_arn = var.dami_user_arn
policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
access_scope {
  type = "cluster"
}
depends_on = [ aws_eks_access_entry.dami_admin ]
}

