terraform {
  backend "s3" {
    bucket  = "dami-devops-terraform-state-384567542379"
    key     = "eks-cluster/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = false
    profile = "terraform"
  }
}