terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }
#  backend "s3" {
#    bucket = "var.bucket_name"
#    key    = "spaceone_domain/terraform.tfstate"
#    region = "us-west-1"
#  }
  backend "local" {
    path = "./terraform.tfstate"
  }
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "eks" {
#  backend = "s3"
#  config = {
#    bucket  = "var.bucket_name"
#    key     = "eks/terraform.tfstate"
#    region  = "us-west-1"
#  }
  backend = "local"
  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}