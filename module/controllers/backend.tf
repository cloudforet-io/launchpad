terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }
  backend "local" {
    path = "../../data/tfstates/controllers.tfstate"
  }
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../../data/tfstates/eks.tfstate"
  }
}

data "terraform_remote_state" "certificate" {
  backend = "local"
  config = {
    path = "../../data/tfstates/certificate.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token  
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "aws" {
  region = var.region
}