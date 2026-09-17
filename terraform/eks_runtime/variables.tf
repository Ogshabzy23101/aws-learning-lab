variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Existing public subnet used by the NAT Gateway"
  type        = string
}

variable "private_subnet_ids" {
  description = "Existing private subnets used by the EKS node group"
  type        = list(string)
}

variable "private_route_tb_id" {
  description = "Existing private route table ID"
  type        = string
}

variable "cluster_name" {
  description = "Existing EKS cluster name"
  type        = string
}

variable "node_role_arn" {
  description = "Existing IAM role ARN for EKS worker nodes"
  type        = string
}

variable "node_group_name" {
  description = "Managed node group name"
  type        = string
  default     = "devops-lab-ng"
}
variable "cluster_autoscaler_arn" {
  description = "arn for the cas role"
  type        = string

}
variable "service_account" {
  description = "Managed node group name"
  type        = string
}