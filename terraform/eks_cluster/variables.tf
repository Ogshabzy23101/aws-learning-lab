variable "cluster_name" {
  description = "value"
  type        = string
}
variable "cluster_role" {
  description = "value"
  type        = string
}
variable "subnet_ids" {
  description = "private subnet id which cluster is located"
  type        = list(string)
}

variable "dami_user_arn" {
  description = "dami admin user arn"
  type = string
}