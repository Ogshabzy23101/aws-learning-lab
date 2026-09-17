# EKS Runtime Terraform

This Terraform provisions infrastructure such as the node group, NAT gateway, and routes for private subnets to the NAT gateway. This infrastructure will be used for EKS practice.

Terraform state files are stored remotely in an S3 bucket. This is configured in the backend file, and sensitive backend data is provisioned in the HCL file, which will be ignored in .gitignore for security purposes.

iam arn :"arn:aws:iam::384567542379:policy/devops-lab-cluster-autoscaler-policy"